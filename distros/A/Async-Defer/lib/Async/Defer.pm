package Async::Defer;
use 5.012;
use warnings;
use strict;
use Carp;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our $VERSION = 'v1.0.0';

use Scalar::Util qw( refaddr );
use List::Util qw( any );

## no critic (ProhibitBuiltinHomonyms)

use constant NOT_RUNNING=> -1;
use constant OP_CODE    => 1;
use constant OP_DEFER   => 2;
use constant OP_IF      => 3;
use constant OP_ELSE    => 4;
use constant OP_ENDIF   => 5;
use constant OP_WHILE   => 6;
use constant OP_ENDWHILE=> 7;
use constant OP_TRY     => 8;
use constant OP_CATCH   => 9;
use constant OP_FINALLY => 10;
use constant OP_ENDTRY  => 11;

my %SELF;


sub new {
    my ($class) = @_;
    my $this = bless {}, $class;
    $SELF{refaddr $this} = {
        parent  => undef,      # parent Defer object, if any
        opcode  => [],         # [[OP_CODE,$sub], [OP_TRY], ...]
        pc      => NOT_RUNNING,# point to _CURRENT_ opcode, if any
        iter    => [],         # [[1,$outer_while_pc], [8,$inner_while_pc], ...]
        findone => undef,      # undef or ['continue'] or ['break'] or ['throw',$err]
    };
    return $this;
}

sub DESTROY {
    my ($this) = @_;
    delete $SELF{refaddr $this};
    return;
}

sub clone {
    my ($this) = @_;
    my $self = $SELF{refaddr $this};

    my $clone = __PACKAGE__->new();
    my $clone_self = $SELF{refaddr $clone};

    $clone_self->{opcode} = [ @{ $self->{opcode} } ];
    %{$clone} = %{$this};
    return $clone;
}

sub iter {
    my ($this) = @_;
    my $self = $SELF{refaddr $this};

    if (!@{ $self->{iter} }) {
        croak 'iter() can be used only inside while';
    }

    return $self->{iter}[-1][0];
}

sub _add {
    my ($this, $op, @params) = @_;
    my $self = $SELF{refaddr $this};

    if ($self->{pc} != NOT_RUNNING) {
        croak 'unable to modify while running';
    }

    push @{ $self->{opcode} }, [ $op, @params ];
    return $this;
}

sub do {
    my ($this, $task, @more_tasks) = @_;
    if(@more_tasks){
        for ($task, @more_tasks) {
            $this->do($_);
        }
        return $this;
    }
    given (ref $task) {
        when ('CODE') {
            return $this->_add(OP_CODE, $task);
        }
        when (__PACKAGE__) {
            return $this->_add(OP_DEFER, $task);
        }
        when ('ARRAY') {
            my %task = map { $_ => $task->[$_] } 0 .. $#{ $task };
            return $this->_add(OP_CODE, _do_batch(1, %task));
        }
        when ('HASH') {
            return $this->_add(OP_CODE, _do_batch(0, %{ $task }));
        }
        default {
            croak 'require CODE/Defer object or ARRAY/HASH in first param'
        }
    }
}

sub _do_batch {
    my ($is_array, %task) = @_;

    # Isolate each task in own Defer object to guarantee they won't be
    # surprised by shared state.
    for my $key (keys %task) {
        my $task;
        given (ref $task{$key}) {
            when ('CODE') {
                $task = __PACKAGE__->new();
                $task->do( $task{$key} );
            }
            when (__PACKAGE__) {
                $task = $task{$key}->clone();
            }
            default {
                my $pos = $is_array ? $key+1 : "{$key}";
                croak 'require CODE/Defer object in param '.$pos;
            }
        }
        $task{$key} = $task;
    }

    return sub{
        my ($d, @taskparams) = @_;
        my %taskparams
            = !$is_array ? (@taskparams)
            :              (map { ($_ => $taskparams[$_]) } 0 .. $#taskparams);

        if (!keys %task) {
            return $d->done();
        }

        my %taskresults = map { $_ => undef } keys %task;
        for my $key (sort keys %task) {     # sort just to simplify testing
            my $t = __PACKAGE__->new();
            $t->try();
                $t->do( $task{$key} );
            $t->catch(
                qr/.*/ms => sub{
                    my ($t,$err) = @_;      ## no critic (ProhibitReusedNames)
                    $t->{err} = $err;
                    $t->done();
                },
                FINALLY => sub{
                    my ($t, @result) = @_;  ## no critic (ProhibitReusedNames)
                    $taskresults{$key} = $t->{err} // \@result;
                    if (!any {!defined} values %taskresults) {
                        my @taskresults
                            = !$is_array ? %taskresults
                            :              map { $taskresults{$_-1} } 1 .. keys %taskresults;
                        $d->done(@taskresults);
                    }
                    return $t->done();
                },
            );
            $t->run( undef, @{ $taskparams{$key} || [] } );
        }
    };
}

sub if {
    my ($this, $code) = @_;
    if (!$code || ref $code ne 'CODE') {
        croak 'require CODE in first param';
    }
    return $this->_add(OP_IF, $code);
}

sub else {
    my ($this) = @_;
    return $this->_add(OP_ELSE);
}

sub end_if {
    my ($this) = @_;
    return $this->_add(OP_ENDIF);
}

sub while {
    my ($this, $code) = @_;
    if (!$code || ref $code ne 'CODE') {
        croak 'require CODE in first param';
    }
    return $this->_add(OP_WHILE, $code);
}

sub end_while {
    my ($this) = @_;
    return $this->_add(OP_ENDWHILE);
}

sub try {
    my ($this) = @_;
    return $this->_add(OP_TRY);
}

sub catch {
    my ($this, @param) = @_;
    if (2 > @param) {
        croak 'require at least 2 params';
    } elsif (@param % 2) {
        croak 'require even number of params';
    }

    my ($finally, @catch);
    while (my ($cond, $code) = splice @param, 0, 2) {
        if ($cond eq 'FINALLY') {
            $finally ||= $code;
        } else {
            push @catch, $cond, $code;
        }
    }

    if (@catch) {
        $this->_add(OP_CATCH, @catch);
    }
    if ($finally) {
        $this->_add(OP_FINALLY, $finally);
    }
    return $this->_add(OP_ENDTRY);
}

sub _check_stack {
    my ($self) = @_;
    my @stack;
    my %op_open  = (
        OP_IF()         => 'end_if()',
        OP_WHILE()      => 'end_while()',
        OP_TRY()        => 'catch()',
    );
    my %op_close = (
        OP_ENDIF()      => [ OP_IF,     'end_if()'      ],
        OP_ENDWHILE()   => [ OP_WHILE,  'end_while()'   ],
        OP_ENDTRY()     => [ OP_TRY,    'catch()'       ],
    );
    my $extra = 0;
    for (my $i = 0; $i < @{ $self->{opcode} }; $i++) {
        my ($op) = @{ $self->{opcode}[ $i ] };

        if ($op == OP_CATCH || $op == OP_FINALLY) {
            $extra++;
        }

        if ($op_open{$op}) {
            push @stack, [$op,0];   # second number is counter for seen OP_ELSE
        }
        elsif ($op_close{$op}) {
            my ($close_op, $close_func) = @{ $op_close{$op} };
            if (@stack && $stack[-1][0] == $close_op) {
                pop @stack;
            } else {
                croak 'unexpected '.$close_func.' at operation '.($i+1-$extra);
            }
        }
        elsif ($op == OP_ELSE) {
            if (!(@stack && $stack[-1][0] == OP_IF)) {
                croak 'unexpected else() at operation '.($i+1-$extra);
            }
            elsif ($stack[-1][1]) {
                croak 'unexpected double else() at operation '.($i+1-$extra);
            }
            $stack[-1][1]++;
        }
    }
    if (@stack) {
        croak 'expected '.$op_open{ $stack[-1][0] }.' at end';
    }
    return;
}

sub run {
    my ($this, $d, @result) = @_;
    my $self = $SELF{refaddr $this};

    my %op_stmt = map {$_=>1} OP_CODE, OP_DEFER, OP_FINALLY;
    if (!any {$op_stmt{ $_->[0] }} @{ $self->{opcode} }) {
        croak 'no operations to run, use do() first';
    }
    if ($self->{pc} != NOT_RUNNING) {
        croak 'already running';
    }
    _check_stack($self);

    if(ref($d) eq 'CODE') {
        my $callback = $d;
        $d = __PACKAGE__->new();
        $d->do(
            sub {
                my ($defer, @results) = @_;
                $callback->(@results);
                $defer->done;
            }
        );
    }

    $self->{parent} = $d;
    $this->done(@result);
    return;
}

sub _op {
    my ($self) = @_;
    my ($op, @params) = @{ $self->{opcode}[ $self->{pc} ] };
    return wantarray ? ($op, @params) : $op;
}

sub done {
    my ($this, @result) = @_;
    my $self = $SELF{refaddr $this};

    # If OP_FINALLY was called while processing continue(), break() or throw(),
    # and it has finished with done() - continue with continue/break/throw by
    # calling them _again_ instead of done().
    if ($self->{findone}) {
        my ($method, @param) = @{ $self->{findone} };
        return $this->$method(@param);
    }

    while (++$self->{pc} <= $#{ $self->{opcode} }) {
        my ($opcode, @param) = _op($self);

        # @result received from previous opcode will be available to next
        # opcode only if these opcodes stay one-after-one without any
        # other opcodes between them (like OP_IF, for example).
        # Only exception is (no-op) OP_TRY, OP_CATCH and OP_ENDTRY.
        # This limitation should help user to avoid subtle bugs.
        given ($opcode) {
            when (OP_CODE) {
                return $param[0]->($this, @result);
            }
            when (OP_DEFER) {
                return $param[0]->run($this, @result);
            }
            when (OP_FINALLY) {
                return $param[0]->($this, @result);
            }
            when ([OP_TRY,OP_CATCH,OP_ENDTRY]) {
                next;
            }
        }
        @result = ();

        given ($opcode) {
            when (OP_IF) {
                # true  - do nothing (i.e. just move to next opcode)
                # false - skip to nearest OP_ELSE or OP_ENDIF
                if (!$param[0]->( $this )) {
                    my $stack = 0;
                    while (++$self->{pc} <= $#{ $self->{opcode} }) {
                        my $op = _op($self);
                          $op == OP_ELSE  && !$stack    ? last
                        : $op == OP_ENDIF && !$stack    ? last
                        : $op == OP_IF                  ? $stack++
                        : $op == OP_ENDIF               ? $stack--
                        :                                 next;
                    }
                }
            }
            when (OP_ELSE) {
                # skip this OP_ELSE branch to nearest OP_ENDIF
                my $stack = 0;
                while (++$self->{pc} <= $#{ $self->{opcode} }) {
                    my $op = _op($self);
                      $op == OP_ENDIF && !$stack    ? last
                    : $op == OP_IF                  ? $stack++
                    : $op == OP_ENDIF               ? $stack--
                    :                                 next;
                }
            }
            when (OP_WHILE) {
                # We can "enter" OP_WHILE in two cases - for the first time,
                # OR because of continue() called inside this OP_WHILE.
                if (!@{$self->{iter}} || $self->{iter}[-1][1] != $self->{pc}) {
                    push @{ $self->{iter} }, [ 1, $self->{pc} ];
                }
                # We now already "inside" this OP_WHILE, so we can use break()
                # to exit _this_ OP_WHILE.
                if (!$param[0]->( $this )) {
                    return $this->break();
                }
            }
            when (OP_ENDWHILE) {
                # We now still "inside" current OP_WHILE, so we can use continue()
                # to repeat _this_ OP_WHILE.
                return $this->continue();
            }
        }
    }

    $self->{pc} = NOT_RUNNING;
    if ($self->{parent}) {
        return $self->{parent}->done(@result);
    }

    # If we're here, done() was called by last opcode, and this is
    # top-level Defer object, nothing more to do - STOP.
}

# Before executing continue/break logic we have to find and execute all
# OP_FINALLY for all already open OP_TRY blocks within this OP_WHILE.
# So, this helper skip opcodes inside this OP_WHILE until it found
# either OP_FINALLY or OP_ENDWHILE or last opcode.
sub _skip_while {
    my ($self) = @_;

    # 1. continue() can be called exactly on OP_ENDWHILE (by done())
    # 2. continue/break can be called by last opcode
    # In both cases we shouldn't do anything (including moving {pc} forward).
    if (_op($self) == OP_ENDWHILE || $self->{pc} == $#{ $self->{opcode} }) {
        return;
    }

    my $stack = 0;
    my $trystack = 0;
    while (++$self->{pc} < $#{ $self->{opcode} }) {
        my $op = _op($self);
          $op == OP_ENDWHILE && !$stack     ? last
        : $op == OP_WHILE                   ? $stack++
        : $op == OP_ENDWHILE                ? $stack--
        : $op == OP_TRY                     ? $trystack++
        : $op == OP_ENDTRY && $trystack     ? $trystack--
        : $op == OP_FINALLY && !$trystack   ? last
        :                                     next;
    }

    return;
}

sub continue {
    my ($this) = @_;
    my $self = $SELF{refaddr $this};

    # Any next call to continue/break/throw cancels current continue/break/throw (if any).
    $self->{findone} = undef;

    _skip_while($self);
    my ($op, @param) = _op($self);
    if ($op == OP_FINALLY) {
        # If OP_FINALLY ends with done() - call continue() again instead.
        $self->{findone} = ['continue'];
        return $param[0]->($this);
    }

    # We now at OP_ENDWHILE, rewind to corresponding OP_WHILE.
    my $stack = 0;
    while (--$self->{pc} > 0) {
        $op = _op($self);
          $op == OP_WHILE && !$stack    ? last
        : $op == OP_ENDWHILE            ? $stack++
        : $op == OP_WHILE               ? $stack--
        :                                 next;
    }

    # If continue was called outside OP_WHILE there is no iteration number.
    if (@{ $self->{iter} }) {
        $self->{iter}[-1][0]++;
    }

    # Step one opcode back because done() will move one opcode forward
    # and so process this OP_WHILE.
    --$self->{pc};
    return $this->done();
}

sub break {
    my ($this) = @_;
    my $self = $SELF{refaddr $this};

    # Any next call to continue/break/throw cancels current continue/break/throw (if any).
    $self->{findone} = undef;

    _skip_while($self);
    my ($op, @param) = _op($self);
    if ($op == OP_FINALLY) {
        # If OP_FINALLY ends with done() - call break() again instead.
        $self->{findone} = ['break'];
        return $param[0]->($this);
    }

    # We now at OP_ENDWHILE.
    pop @{ $self->{iter} };
    return $this->done();
}

sub throw {
    my ($this, $err) = @_;
    my $self = $SELF{refaddr $this};
    $err //= q{};

    # Any next call to continue/break/throw cancels current continue/break/throw (if any).
    $self->{findone} = undef;

    # If throw() was called by break opcode in this OP_TRY (either OP_FINALLY,
    # or OP_CATCH if there no OP_FINALLY in this OP_TRY), then we should look
    # for handler in outer OP_TRY, not in this one.
    # So we set $stack=1 to skip over current OP_TRY's OP_ENDTRY.
    my ($nextop) = @{ $self->{opcode}[ $self->{pc} + 1 ] || [] };
    my $stack = $nextop && $nextop == OP_ENDTRY ? 1 : 0;
    # Skip until OP_CATCH or OP_FINALLY in current OP_TRY block.
    # If while skipping we exit some OP_WHILE(s) - pop their iterators.
    while (++$self->{pc} <= $#{ $self->{opcode} }) {
        my $op = _op($self);
          $op == OP_CATCH   && !$stack      ? last
        : $op == OP_FINALLY && !$stack      ? last
        : $op == OP_TRY                     ? $stack++
        : $op == OP_ENDTRY                  ? $stack--
        : $op == OP_WHILE                   ? push @{ $self->{iter} }, [ 1, $self->{pc} ]
        : $op == OP_ENDWHILE                ? pop  @{ $self->{iter} }
        :                                     next;
    }

    if ($self->{pc} > $#{ $self->{opcode} }) {
        if ($self->{parent}) {
            return $self->{parent}->throw($err);
        } else {
            croak 'uncatched exception in Defer: '.$err;
        }
    }

    my ($op, @param) = _op($self);
    if ($op == OP_CATCH) {
        while (my ($cond, $code) = splice @param, 0, 2) {
            if ($err =~ /$cond/ms) {
                return $code->($this, $err);
            }
        }
        # Re-throw exception if no one regex in this OP_CATCH match it.
        return $this->throw($err);
    }
    else { # OP_FINALLY
        # If OP_FINALLY ends with done() - call throw($err) again instead.
        $self->{findone} = ['throw', $err];
        return $param[0]->($this, $err);
    }
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Async::Defer - VM to write and run async code in usual sync-like way


=head1 VERSION

This document describes Async::Defer version v1.0.0


=head1 SYNOPSIS

    use Async::Defer;

    # ... CREATE

    my $defer  = Async::Defer->new();
    my $defer2 = $defer->clone();

    # ... SETUP

    $defer->do(sub{
        my ($d, @param) = @_;
        # run sync/async code which MUST end with one of:
        # $d->done(@result);
        # $d->throw($error);
        # $d->continue();
        # $d->break();
    });

    $defer->if(sub{ my $d=shift; return 1 });

      $defer->try();

        $defer->do($defer2);

      $defer->catch(
        qr/^io:/    => sub{
            my ($d,$err) = @_;
            # end with $d->done/throw/continue/break
        },
        qr/.*/      => sub{     # WILL CATCH ALL EXCEPTIONS
            my ($d,$err) = @_;
            # end with $d->done/throw/continue/break
        },
        FINALLY     => sub{
            my ($d,$err,@result) = @_;
            # end with $d->done/throw/continue/break
        },
      );

    $defer->else();

      $defer->while(sub{ my $d=shift; return $d->iter() <= 3 });

        $defer->do(sub{
            my ($d) = @_;
            # may access $d->iter() here
            # end with $d->done/throw/continue/break
        });

      $defer->end_while();

    $defer->end_if();

    $defer->{anyvar} = 'anyval';

    # ... START

    $defer->run();


=head1 DESCRIPTION

B<WARNING: This is experimental code, public interface may change.>

This module's goal is to simplify writing complex async event-based code,
which usually mean huge amount of callback/errback functions, very hard to
support. It was initially inspired by Python/Twisted's
L<Deferred|http://twistedmatrix.com/documents/10.1.0/core/howto/defer.html>
object, but go further and provide virtual machine which allow you to
write/define complete async program (which consists of many
callback/errback) in sync way, just like you write usual non-async
programs.

Main idea is simple. For example, if you've this non-async code:

    $var = fetch_val();
    process_val( $var );

and want to make C<fetch_val()> async, you usually do something like this:

    fetch_val( cb => \&value_fetched );
    sub value_fetched {
        my ($var) = @_;
        process_val( $var );
    }

With Async::Defer you will split initial non-async code in sync parts (usually
this mean - split on assignment operator):

    ### 1
           fetch_val();
    ### 2
    $var =
    process_val( $var );

then wrap each part in separate anon sub and add Defer object to join
these parts together:

    $d = Async::Defer->new();
    $d->do(sub{
        my ($d) = @_;
        fetch_val( $d );    # will call $d->done('…result…') when done
    });
    $d->do(sub{
        my ($d, $var) = @_;
        process_val( $var );
        $d->done();         # this sub is sync, it call done() immediately
    });
    $d->run();

These anon subs are similar to I<statements> in perl. Between these
I<statements> you can use I<flow control> operators like C<if()>,
C<while()> and C<try()>/C<catch()>. And inside I<statements> you can
control execution flow using C<done()>, C<throw()>, C<continue()>
and C<break()> operators when current async function will finish and
will be ready to go to the continue step.
Finally, you can use Async::Defer object to keep your I<local variables> -
this object is empty hash, and you can create any keys in it.
Single Defer object described this way is sort of single I<function>.
And it's possible to I<call> another functions by using another Defer
object as parameter for C<do()> instead of usual anon sub.

While you can use both sync and async sub in C<do()>, they all B<MUST>
call one of C<done()>, C<throw()>, C<continue()> or C<break()> when they finish
their work, and do this B<ONLY ONCE>. This is Defer's way to proceed from
one step to another, and if not done right Defer object's behaviour is
undefined!


=head2 PERSISTENT STATE, LOCAL VARIABLES and SCOPE

There are several ways to implement this, and it's unclear yet which
way is the best. We can implement full-featured stack with local variables
similar to perl's C<local> using getter/setter methods; we can fill called
Defer objects with copy of all keys in parent Defer object (so called
object will have full read-only access to parent's scalar data, and read/write
access to parent's reference data types); we can do nothing and let user
manually send all needed data to called Defer object as params and get
data back using returned values (by C<done()> or C<throw()>).

In current implementation we do nothing, so here is some ways to go:

    ### @results = another_defer(@params)
    $d->do(sub{
        my ($d) = @_;
        my @params_for_another_defer = (…);
        $d->done(@params_for_another_defer);
    });
    $d->do($another_defer);
    $d->do(sub{
        my ($d, @results_from_another_defer) = @_;
        ...
        $d->done();
    });

    ### share some local variables with $another_defer
    $d->do(sub{
        my ($d) = @_;
        $d->{readonly}  = $scalar;
        $d->{readwrite} = $ref_to_something;
        $another_defer->{readonly}  = $d->{readonly};
        $another_defer->{readwrite} = $d->{readwrite};
        $d->done();
    });
    $d->do($another_defer);
    $d->do(sub{
        my ($d) = @_;
        # $d->{readwrite} here may be modifed by $another_defer
        $d->done();
    });

    ### share all variables with $another_defer (run it manually)
    $d->do(sub{
        my ($d) = @_;
        %$another_defer = %$d;
        $another_defer->run($d);
    });
    $d->do(sub{
        my ($d) = @_;
        # all reference-type keys in $d may be modifed by $another_defer
        $d->done();
    });

If you want to reuse same Defer object several times, then you should keep
in mind: keys created inside this object on first run won't be automatically
removed, so on second and continue runs it will see internal data left by
previous runs. This may or may not be desirable behaviour. In later case
you should use C<clone()> and run only clones of original object (clones are
created using C<%$clone=%$orig>, so they share only reference-type keys
which exists in original Defer):

    $d->do( $another_defer->clone() );
    $d->do( $another_defer->clone() );

=head2 NESTED DEFERS

Async::Defer objects can be nested, and there are two ways to do it.

One way is to add a child defer to the parent defer using C<do()> method.

    my $cd = Async::Defer->new();
    
    ## setup the child defer.
    $cd->do( ... );

    ## parent defer
    my $pd = Async::Defer->new();
    $pd->do( ... );
    $pd->do(sub {
        my $d = shift;
        ...;
        $d->done( @arguments_for_child_defer );
    });
    ## run the child defer
    $pd->do($cd);
    $pd->do(sub {
        my ($d, @results_from_child_defer) = @_;
        ...;
    });

The other way is to call C<run()> on the child defer with its first
argument being the parent defer. This is very useful when you dynamically
create the child defer in statements of the parent defer.

    ## parent defer
    my $pd = Async::Defer->new();
    $pd->do(sub {
        my ($d, @args) = @_;
    
        ## create the child defer in the statement
        my $cd = Async::Defer->new();
        
        ## setup the child defer
        $cd->do( ... );
    
        ## run() the child.
        ## You do not have to call $d->done explicitly,
        ## because the flow continues from the child to the parent.
        $cd->run($d, @argments_for_child_defer);
    });
    $pd->do(sub {
        my ($d, @results_from_child_defer) = @_;
        ...;
    });


=head1 EXPORTS

Nothing.


=head1 INTERFACE 

=over

=item new()

Create and return Async::Defer object.

=item clone()

Clone existing Async::Defer object and return clone.

Clone will have same I<program> (I<STATEMENTS> and I<OPERATORS> added to
original object) and same I<local variables> (non-deep copy of orig object
keys using C<%$clone=%$orig>). After cloning these two objects can be
modified (by adding new I<STATEMENTS>, I<OPERATORS> and modifying variables)
independently.

It's possible to C<clone()> object which is running right now, cloned object
will not be in running state - this is safe way to C<run()> objects which may
or may not be already running.

=item run( [ $parent_defer, @params ] )

=item run( [ \&callback, @params ] )

Start executing object's current I<program>, which must be defined first by
adding at least one I<STATEMENT> (C<do()> or C<<catch(FINALLY=>sub{})>>)
to this object.

Usually while C<run()> only first I<STATEMENT> will be executed (with optional
C<@params> in parameters). It will just start some async function and
returns, and C<run()> will returns immediately after this too. Actual
execution of this object will continue when started async function will
finish (usually after Timer or I/O event) and call this object's C<done()>,
C<break()>, C<continue()> or C<throw()> methods.

It's possible to make all I<STATEMENTS> sync - in this case full I<program>
will be executed before returning from C<run()> - but this has no real sense
because you don't need Defer object for sync programs.

If C<run()> used to start top-level I<program> (i.e. without C<$parent_defer>
parameter), then there will be no I<return value> at end of I<program> -
after break I<STATEMENT> in this object will call C<done()> nothing else will
happens and any parameters of that break C<done()> call will be ignored.
If this Defer object was started as part of another I<program> (i.e. it was
added there using C<do()> or just manually executed from some I<STATEMENT> with
defined C<$parent_defer> parameter), then it I<return value> will be delivered
to continue I<STATEMENT> in C<$parent_defer> object (See L</"NESTED DEFERS">).

The first argument for C<run()> may also be a subroutine reference (C<\&callback>).
In this case, the callback is called after break I<STATEMENT> in this object.
The arguments for the callback are the results of the break I<STATEMENT>.
Any value returned from C<\&callback> will be ignored.

=item iter()

This method available only inside C<while()> - both in C<while()>'s
C<\&conditional> argument and C<while()>'s body I<STATEMENTS>. It return
current iteration number for nearest C<while()>, starting from 1.

    # this loop will execute 3 times:
    $d->while(sub{  shift->iter() <= 3  });
        $d->do(sub{
            my ($d) = @_;
            printf "Iteration %d\n", $d->iter();
            $d->done();
        });
    $d->end_while();

=back

=head2 STATEMENTS and OPERATORS

All I<STATEMENTS> methods return the Async::Defer object,
so that you can chain method calls.

=over

=item do( \&sync_or_async_code, … )

=item do( $child_defer, … )

Add I<STATEMENT> to this object's I<program>.

When this I<STATEMENT> should be executed, C<\&sync_or_async_code>
(or C<$child_defer>'s first I<STATEMENT>) will be called with these params:

    ( $defer_object, @optional_results_from_previous_STATEMENT )

C<do()> accepts multiple arguments. Those I<STATEMENTS> are added to the object
in that order, and can be mix of any types - i.e. it's same as call C<do()>
sequentially multiple times providing these arguments one-by-one.

    do(
        \&code,
        $defer,
        [$defer1, $defer2, \&code3],
        {
            task1 => $defer4,
            task2 => \&code5,
        },
        \&more_code,
        …
    );

=item do( [\&sync_or_async_code, $child_defer, …], … )

=item do( {task1=>\&sync_or_async_code, task2=>$child_defer, …}, … )

Add one I<STATEMENT> to this object's I<program>.

When this I<STATEMENT> should be executed, all these tasks will be started
simultaneously (Defer objects using C<clone()> and C<run()>, code by
transforming into new Defer object and then also C<run()>).
This I<program> will continue only after all these tasks will be finished
(either with C<done()> or C<throw()>).

It's possible to provide params individually for each of these tasks and
receive results/error returned by each of these tasks, but actual syntax
depends on how these tasks was named - by id (ARRAY) or by name (HASH):

    $d->do(sub{
        my ($d) = @_;
        $d->done(
            ['param1 for task1', 'param2 for task1'],
            ['param1 for task2'],
            [undef,              'param2 for task3'],
            # no params for task4,task5,…
        );
    });
    $d->do([ $d_task1, $d_task2, $d_task3, $d_some, $d_some ]);
    $d->do(sub{
        my ($d, @taskresults) = @_;
        my $id = 1;
        if (ref $taskresults[$id-1]) {
            print "task $id results:",  @{ $taskresults[$id-1] };
        } else {
            print "task $id throw error:", $taskresults[$id-1];
        }
    });

    $d->do(sub{
        my ($d) = @_;
        $d->done(
            task1 => ['param1 for task1', 'param2 for task1'],
            task2 => ['param1 for task2'],
            task3 => [undef,              'param2 for task3'],
            # no params for task4,task5,…
        );
    });
    $d->do({
        task1 => $d_task1,
        task2 => $d_task2,
        task3 => $d_task3,
        task4 => $d_some,
        task5 => $d_some,
    });
    $d->do(sub{
        my ($d, %taskresults) = @_;
        if (ref $taskresults{task1}) {
            print "task1 results:",  @{ $taskresults{task1} };
        } else {
            print "task1 throw error:", $taskresults{task1};
        }
    });

=item if( \&conditional )

=item else()

=item end_if()

Add conditional I<OPERATOR> to this object's I<program>.

When this I<OPERATOR> should be executed, C<\&conditional> will be called
with single param:

    ( $defer_object )

The C<\&conditional> B<MUST> be sync, and return true/false.

=item while( \&conditional )

=item end_while()

Add loop I<OPERATOR> to this object's I<program>.

When this I<OPERATOR> should be executed, C<\&conditional> will be called with
single param:

    ( $defer_object )

The C<\&conditional> B<MUST> be sync, and return true/false.

=item try()

=item catch( $regex_or_FINALLY => \&sync_or_async_code, ... )

Add exception handling to this object's I<program>.

In general, try/catch/finally behaviour is same as in Java (and probably
many other languages).

If some I<STATEMENTS> inside try/catch block will C<throw()>, the thrown error
can be intercepted (using matching regexp in C<catch()>) and handled in any
way (blocked - if C<catch()> handler call C<done()>, C<continue()> or C<break()> or
replaced by another exception - if C<catch()> handler call C<throw()>).
If exception match more than one regexp, first successfully matched
regexp's handler will be used. Handler will be executed with params:

    ( $defer_object, $error )

In addition to exception handlers you can also define FINALLY handler
(by using string C<"FINALLY"> instead of regex). FINALLY handler will be
called in any case (with/without exception) and may handle this in any way
just like any other exception handler in C<catch()>. FINALLY handler will
be executed with different params:

    # with exception
    ( $defer_object, $error)
    # without exception
    ( $defer_object, @optional_results_from_previous_STATEMENT )

=back

=head2 FLOW CONTROL in STATEMENTS

Unless you are nesting child defers, one and only one of these methods B<MUST> be
called at end of each I<STATEMENT>, both sync and async!
In the case of nested defers, see L</"NESTED DEFERS">.

=over

=item done( @optional_result )

Go to continue I<STATEMENT>/I<OPERATOR>. If continue is I<STATEMENT>, it will receive
C<@optional_result> in it parameters.

=item throw( $error )

Throw exception. Nearest matching C<catch()> or FINALLY I<STATEMENT> will be
executed and receive C<$error> in it parameter.

=item continue()

Move to beginning of nearest C<while()> (or to first I<STATEMENT> if
called outside C<while()>) and continue with continue iteration (if C<while()>'s
C<\&conditional> still returns true).

=item break()

Move to first I<STATEMENT>/I<OPERATOR> after nearest C<while()> (or finish this
I<program> if called outside C<while()> - returning to parent's Defer object
if any).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Async-Defer/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Async-Defer>

    git clone https://github.com/powerman/perl-Async-Defer.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Async-Defer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Async-Defer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Async-Defer>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Async-Defer>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Async-Defer>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 CONTRIBUTORS

Toshio Ito C<< toshioito [at] cpan.org >>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011-2012 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
