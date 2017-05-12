package AI::Prolog::Engine;
$REVISION = '$Id: Engine.pm,v 1.13 2005/08/06 23:28:40 ovid Exp $';
$VERSION  = '0.4';
use strict;
use warnings;
use Carp qw( confess carp );

use Scalar::Util qw/looks_like_number/;
use Hash::Util 'lock_keys';

use aliased 'AI::Prolog::Term';
use aliased 'AI::Prolog::Term::Cut';
use aliased 'AI::Prolog::Term::Number';
use aliased 'AI::Prolog::TermList';
use aliased 'AI::Prolog::TermList::Step';
use aliased 'AI::Prolog::TermList::Primitive';
use aliased 'AI::Prolog::KnowledgeBase';
use aliased 'AI::Prolog::Parser';
use aliased 'AI::Prolog::ChoicePoint';

use AI::Prolog::Engine::Primitives;

use constant OnceMark => 'OnceMark';

# The engine is what executes prolog queries.
# Author emeritus:  Dr. Michael Winikoff
# Translation to Perl:  Curtis "Ovid" Poe

# $prog An initial program - this will be extended
# $term The query to be executed

# This governs whether tracing is done
sub trace {
    my $self = shift;
    if (@_) {
        $self->{_trace} = shift;
        return $self;
    }
    return $self->{_trace};
}

sub halt {
    my $self = shift;
    if (@_) {
        $self->{_halt} = shift;
        return $self;
    }
    return $self->{_halt};
}

my $FORMATTED = 1;

sub formatted {
    my $self = shift;
    if (@_) {
        $FORMATTED = shift;
        return $self;
    }
    return $FORMATTED;
}

my $RAW_RESULTS;

sub raw_results {
    my $self = shift;
    if (@_) {
        $RAW_RESULTS = shift;
        if ($RAW_RESULTS) {
            $self->formatted(0);
        }
        return $self;
    }
    return $RAW_RESULTS;
}

my $BUILTIN = 0;

sub _adding_builtins {
    my $self = shift;
    if (@_) {
        $BUILTIN = shift;
        return $self;
    }
    return $BUILTIN;
}

sub new {
    my ( $class, $term, $prog ) = @_;
    my $self = bless {

        # The stack holds choicepoints and a list of variables
        # which need to be un-bound upon backtracking.
        _stack          => [],
        _db             => KnowledgeBase->new,
        _goal           => TermList->new( $term, undef ),    # TermList
        _call           => $term,                            # Term
        _run_called     => undef,
        _cp             => undef,
        _retract_clause => undef,
        _trace       => 0,       # whether or not tracing is done
        _halt        => 0,       # will stop the aiprolog shell
        _perlpackage => undef,
        _step_flag   => undef,
    } => $class;
    lock_keys %$self;

    # to add a new primitive, use the binding operator (:=) to assign a unique
    # index to the primitive and add the corresponding definition to
    # @PRIMITIVES.
    eval {
        $self->_adding_builtins(1);
        $self->{_db} = Parser->consult( <<'        END_PROG', $prog );
            ne(X, Y) :- not(eq(X,Y)).
            if(X,Y,Z) :- once(wprologtest(X,R)) , wprologcase(R,Y,Z).
            wprologtest(X,yes) :- call(X). wprologtest(X,no). 
            wprologcase(yes,X,Y) :- call(X). 
            wprologcase(no,X,Y) :- call(Y).
            not(X)  :- if(X,fail,true). 
            or(X,Y) :- call(X).
            or(X,Y) :- call(Y).
            true. 
            % the following are handled internally.  Don't use the
            % := operator.  Eventually, I'll make this a fatal error.
            % See AI::Prolog::Engine::Builtins to see the code for these
            !          :=  1.
            call(X)    :=  2. 
            fail       :=  3. 
            consult(X) :=  4.
            assert(X)  :=  5.
            retract(X) :=  7.
            retract(X) :- retract(X).
            listing    :=  8.
            listing(X) :=  9.
            print(X)   := 10.
            write(X)   := 10.
            println(X) := 11.
            writeln(X) := 11.
            nl         := 12. 
            trace      := 13.
            notrace    := 13.
            is(X,Y)    := 15.
            gt(X,Y)    := 16.
            lt(X,Y)    := 17.
            ge(X,Y)    := 19.
            le(X,Y)    := 20.
            halt       := 22.
            var(X)     := 23.
            %seq(X)     := 30.
            help       := 31.
            help(X)    := 32.
            gensym(X)  := 33.
            perlcall2(X,Y) := 34.
            eq(X,X).
            not(X) :- X, !, fail.
            not(X).
            %if(X, Yes, _ ) :- seq(X), !, seq(Yes).
            %if(X, _  , No) :- seq(No).
            %if(X, Yes) :- seq(X), !, seq(Yes).
            %if(X, _  ).
            %or(X,Y) :- seq(X).
            %or(X,Y) :- seq(Y).
            once(X) :- X , !.
        END_PROG
        $self->_adding_builtins(0);
    };
    if ($@) {
        croak("Engine->new failed.  Cannot parse default program: $@");
    }
    $self->{_retract_clause} = $self->{_db}->get("retract/1");
    $self->{_goal}->resolve( $self->{_db} );
    return $self;
}

sub query {
    my ( $self, $query ) = @_;
    $self->{_stack}      = [];
    $self->{_run_called} = undef;
    $self->{_goal}       = TermList->new($query);
    $self->{_call}       = $query;
    $self->{_goal}->resolve( $self->{_db} );
    return $self;
}

sub _stack { shift->{_stack} }
sub _db    { shift->{_db} }
sub _goal  { shift->{_goal} }
sub _call  { shift->{_call} }

sub dump_goal {
    my ($self) = @_;
    if ( $self->{_goal} ) {
        _print( "\n= Goals: " . $self->{_goal}->to_string );
        _print(
            "\n==> Try:  " . $self->{_goal}->next_clause->to_string . "\n" )
            if $self->{_goal}->next_clause;
    }
    else {
        _print("\n= Goals: null\n");
    }
}

sub results {
    my $self = shift;
    if ( $self->{_run_called} ) {
        return unless $self->backtrack;
    }
    else {
        $self->{_run_called} = 1;
    }
    $self->_run;
}

sub _run {
    my ($self) = @_;
    my $stackTop = 0;

    while (1) {
        $stackTop = @{ $self->{_stack} };

        if ( $self->{_goal} && $self->{_goal}->isa(Step) ) {
            $self->{_goal} = $self->{_goal}->next;
            if ( $self->{_goal} ) {
                $self->{_goal}->resolve( $self->{_db} );
            }
            $self->{_step_flag} = 1;
            $self->trace(1);
        }
        $self->dump_goal if $self->{_trace};
        $self->step      if $self->{_step_flag};

        unless ( $self->{_goal} ) {

            # we've succeeded.  return results
            if ( $self->formatted ) {
                return $self->_call->to_string;
            }
            else {
                my @results = $self->_call->to_data;
                return $self->raw_results
                    ? $results[1]
                    : $results[0];
            }
        }

        unless ( $self->{_goal} && $self->{_goal}{term} ) {
            croak("Engine->run fatal error.  goal->term is null!");
        }
        unless ( $self->{_goal}->{next_clause} ) {
            my $predicate = $self->{_goal}{term}->predicate;
            _warn("WARNING:  undefined predicate ($predicate)\n");
            next if $self->backtrack;    # if we backtracked, try again
            return;                      # otherwise, we failed
        }

        my $clause = $self->{_goal}->{next_clause};
        if ( my $next_clause = $clause->{next_clause} ) {
            push @{ $self->{_stack} } => $self->{_cp}
                = ChoicePoint->new( $self->{_goal}, $next_clause, );
        }
        my $vars      = [];
        my $curr_term = $clause->{term}->refresh($vars);
        if ( $curr_term->unify( $self->{_goal}->term, $self->{_stack} ) ) {
            $clause = $clause->{next};
            if ( $clause && $clause->isa(Primitive) ) {
                if (   !$self->do_primitive( $self->{_goal}->{term}, $clause )
                    && !$self->backtrack )
                {
                    return;
                }
            }
            elsif ( !$clause ) {    # matching against fact
                $self->{_goal} = $self->{_goal}->{next};
                if ( $self->{_goal} ) {
                    $self->{_goal}->resolve( $self->{_db} );
                }
            }
            else {                  # replace goal by clause body
                my ( $p, $p1, $ptail );    # termlists
                for ( my $i = 1; $clause; $i++ ) {

                    # will there only be one CUT?
                    if ( $clause->{term} eq Term->CUT ) {
                        $p = TermList->new( Cut->new($stackTop) );
                    }
                    else {
                        $p = TermList->new( $clause->{term}->refresh($vars) );
                    }

                    if ( $i == 1 ) {
                        $p1 = $ptail = $p;
                    }
                    else {
                        $ptail->next($p);
                        $ptail = $p;    # XXX ?
                    }
                    $clause = $clause->{next};
                }
                $ptail->next( $self->{_goal}->{next} );
                $self->{_goal} = $p1;
                $self->{_goal}->resolve( $self->{_db} );
            }
        }
        else {                          # unify failed.  Must backtrack
            return unless $self->backtrack;
        }
    }
}

sub backtrack {
    my $self = shift;
    _print(" <<== Backtrack: \n") if $self->{_trace};
    while ( @{ $self->{_stack} } ) {
        my $o = pop @{ $self->{_stack} };

        if ( UNIVERSAL::isa( $o, Term ) ) {
            $o->unbind;
        }
        elsif ( UNIVERSAL::isa( $o, ChoicePoint ) ) {
            $self->{_goal} = $o->{goal};

            # XXX This could be very dangerous if we accidentally try
            # to assign a term to itself!  See ChoicePoint->next_clause
            $self->{_goal}->next_clause( $o->{clause} );
            return 1;
        }
    }
    return;
}

sub _print {    # convenient testing hook
    print @_;
}

sub _warn {     # convenient testing hook
    warn @_;
}

use constant RETURN => 2;

sub do_primitive {    # returns false if fails
    my ( $self, $term, $c ) = @_;
    my $primitive = AI::Prolog::Engine::Primitives->find( $c->ID )
        or die sprintf "Cannot find primitive for %s (ID: %d)\n",
        $term->to_string, $c->ID;
    return unless my $result = $primitive->( $self, $term, $c );
    return 1 if RETURN == $result;
    $self->{_goal} = $self->{_goal}->next;
    if ( $self->{_goal} ) {
        $self->{_goal}->resolve( $self->{_db} );
    }
    return 1;
}

1;

__END__

=head1 NAME

AI::Prolog::Engine - Run queries against a Prolog database.

=head1 SYNOPSIS

 my $engine = AI::Prolog::Engine->new($query, $database).
 while (my $results = $engine->results) {
     print "$result\n";
 }

=head1 DESCRIPTION

C<AI::Prolog::Engine> is a Prolog engine implemented in Perl.

The C<new()> function actually bootstraps some Prolog code onto your program to
give you access to the built in predicates listed in the
L<AI::Prolog::Builtins|AI::Prolog::Builtins> documentation.

This documentation is provided for completeness.  You probably want to use
L<AI::Prolog|AI::Prolog>.

=head1 CLASS METHODS

=head2 C<new($query, $database)>

This creates a new Prolog engine.  The first argument must be of type
C<AI::Prolog::Term> and the second must be a database created by
C<AI::Prolog::Parser::consult>.

 my $database = Parser->consult($some_prolog_program);
 my $query    = Term->new('steals(badguy, X).');
 my $engine   = Engine->new($query, $database);
 Engine->formatted(1);
 while (my $results = $engine->results) {
    print $results, $/;
 }

The need to have a query at the same time you're instantiating the engine is a
bit of a drawback based upon the original W-Prolog work.  I will likely remove
this drawback in the future.

=head2 C<formatted([$boolean])>

The default value of C<formatted> is true.  This method, if passed a true
value, will cause C<results> to return a nicely formatted string representing
the output of the program.  This string will loosely correspond with the
expected output of a Prolog program.

If false, all calls to C<result> will return Perl data structures instead of
nicely formatted output.

If called with no arguments, this method returns the current C<formatted>
value.

 Engine->formatted(1); # turn on formatting
 Engine->formatted(0); # turn off formatting (default)
 
 if (Engine->formatted) {
     # test if formatting is enabled
 }

B<Note>: if you choose to use the L<AI::Prolog|AI::Prolog> interface instead of
interacting directly with this class, that interface will set C<formatted> to
false.  You will have to set it back in your code if you do not wish this
behavior:

 use AI::Prolog;
 my $logic = AI::Prolog->new($prog_text);
 $logic->query($query_text);
 AI::Logic::Engine->formatted(1); # if you want formatted to true
 while (my $results = $logic->results) {
    print "$results\n";
 }

=head2 C<raw_results([$boolean])>

The default value of C<raw_results> is false.  Setting this property to a true
value automatically sets C<formatted> to false.  C<results> will return the raw
data structures generated by questions when this property is true.
 
 Engine->raw_results(1); # turn on raw results
 Engine->raw_results(0); # turn off raw results (default)
 
 if (Engine->raw_results) {
     # test if raw results is enabled
 }

=head2 C<trace($boolean)>

Set this to a true value to turn on tracing.  This will trace through the
engine's goal satisfaction process while it's running.  This is very slow.

 Engine->trace(1); # turn on tracing
 Engine->trace(0); # turn off tracing

=head1 INSTANCE METHODS

=head2 C<results()>

This method will return the results from the last run query, one result at a
time.  It will return false when there are no more results.  If C<formatted> is
true, it will return a string representation of those results:

 while (my $results = $engine->results) {
    print "$results\n";
 }

If C<formatted> is false, C<$results> will be an object with methods matching
the variables in the query.  Call those methods to access the variables:

 AI::Prolog::Engine->formatted(0);
 $engine->query('steals(badguy, STUFF, VICTIM).');
 while (my $r = $engine->results) {
     printf "badguy steals %s from %s\n", $r->STUFF, $r->VICTIM;
 }

If necessary, you can get access to the full, raw results by setting
C<raw_results> to true.  In this mode, the results are returned as an array
reference with the functor as the first element and an additional element for
each term.  Lists are represented as array references.

 AI::Prolog::Engine->raw_results(1);
 $engine->query('steals(badguy, STUFF, VICTIM).');
 while (my $r = $engine->results) {
    # do stuff with $r in the form:
    # ['steals', 'badguy', $STUFF, $VICTIM]
 }

=head2 C<query($query)>

If you already have an engine object instantiated, call the C<query()> method
for subsequent queries.  Internally, when calling C<new()>, the engine
bootstraps a set of Prolog predicates to provide the built ins.  However, this
process is slow.  Subsequent queries to the same engine with the C<query()>
method can double the speed of your program.
 
 my $engine   = Engine->new($query, $database);
 while (my $results = $engine->results) {
    print $results, $/;
 }
 $query = Term->new("steals(ovid, X).");
 $engine->query($query);
 while (my $results = $engine->results) {
    print $results, $/;
 }

=head1 BUGS

None known.

=head1 AUTHOR

Curtis "Ovid" Poe, E<lt>moc tod oohay ta eop_divo_sitrucE<gt>

Reverse the name to email me.

This work is based on W-Prolog, http://goanna.cs.rmit.edu.au/~winikoff/wp/,
by Dr. Michael Winikoff.  Many thanks to Dr. Winikoff for granting me
permission to port this.

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Curtis "Ovid" Poe

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

=cut
