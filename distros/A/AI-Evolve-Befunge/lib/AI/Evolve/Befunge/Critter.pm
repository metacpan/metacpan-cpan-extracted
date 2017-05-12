package AI::Evolve::Befunge::Critter;
use strict;
use warnings;

use Language::Befunge;
use Language::Befunge::Storage::Generic::Vec;
use IO::File;
use Carp;
use Perl6::Export::Attrs;
use Scalar::Util qw(weaken);

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(
    # basic values
    qw{ boardsize codesize code color dims maxlen maxsize minsize },
    # token currency stuff
    qw{ tokens codecost itercost stackcost repeatcost threadcost },
    # other objects we manage
    qw{ blueprint physics interp }
);

use AI::Evolve::Befunge::Util;
use aliased 'AI::Evolve::Befunge::Critter::Result' => 'Result';

=head1 NAME

    AI::Evolve::Befunge::Critter - critter execution environment


=head1 DESCRIPTION

This module is where the actual execution of Befunge code occurs.  It
contains everything necessary to set up and run the code in a safe
(sandboxed) Befunge universe.

This universe contains the Befunge code (obviously), as well as the
current board game state (if any).  The Befunge code exists in the
negative vector space (with the origin at 0, Befunge code is below
zero on all axes).  Board game info, if any, exists as a square (or
hypercube) which starts at the origin.

The layout of befunge code space looks like this (for a 2d universe):

       |----------|         |
       |1         |         |
       |09876543210123456789|
    ---+--------------------+---
    -10|CCCCCCCCCC          |-10
     -9|CCCCCCCCCC|         | -9
     -8|CCCCCCCCCC          | -8
     -7|CCCCCCCCCC|         | -7
     -6|CCCCCCCCCC          | -6
     -5|CCCCCCCCCC|         | -5
     -4|CCCCCCCCCC          | -4
     -3|CCCCCCCCCC|         | -3
     -2|CCCCCCCCCC          | -2
     -1|CCCCCCCCCC|         | -1
    --0| - - - - -BBBB - - -|0--
      1|          BBBB      |  1
      2|          BBBB      |  2
      3|          BBBB      |  3
      4|                    |  4
      5|          |         |  5
      6|                    |  6
      7|          |         |  7
      8|                    |  8
      9|          |         |  9
    ---+--------------------+---
       |09876543210123456789|
       |1         |         |
       |----------|         |

Where:

    C is befunge code.   This is the code under test.
    B is boardgame data. Each location is binary 0, 1 or 2 (or
                         whatever tokens the game uses to represent
                         unoccupied spaces, and the various player
                         pieces).  The B section only exists for
                         board game applications.

Everything else is free for local use.  Note that none of this is
write protected - a program is free to reorganize and/or overwrite
itself, the game board, results table, or anything else within the
space it was given.

The universe is implemented as a hypercube of 1 or more dimensions.
The universe size is simply the code size times two, or the board size
times two, whichever is larger.  If the board exists in 2 dimensions
but the code exists in more, the board will be represented as a square
starting at (0,0,...) and will only exist on plane 0 of the non-(X,Y)
axes.

Several attributes of the universe are pushed onto the initial stack,
in the hopes that the critter can use this information to its
advantage.  The values pushed are (in order from the top of the stack
(most accessible) to the bottom (least accessible)):

    * the Physics token (implying the rules of the game/universe)
    * the number of dimensions this universe operates in
    * The number of tokens the critter has left (see LIMITS, below)
    * The   iter cost (see LIMITS, below)
    * The repeat cost (see LIMITS, below)
    * The  stack cost (see LIMITS, below)
    * The thread cost (see LIMITS, below)
    * The code size (a Vector)
    * The maximum storage size (a Vector)
    * The board size (a Vector) if operating in a boardgame universe

If a Critter instance will have it's ->invoke() method called more
than once (for board game universes, it is called once per "turn"),
the storage model is not re-created.  The critter is responsible for
preserving enough of itself to handle multiple invocations properly.
The Language::Befunge Interpreter and Storage model are preserved,
though a new IP is created each time, and (for board game universes)
the board data segment is refreshed each time.


=head1 LIMITS

This execution environment is sandboxed.  Every attempt is made to
keep the code under test from escaping the environment, or consuming
an unacceptable amount of resources.

Escape is prevented by disabling all file operations, I/O operations,
system commands like fork() and system(), and commands which load
(potentially insecure) external Befunge semantics modules.

Resource consumption is limited through the use of a currency system.
The way this works is, each critter starts out with a certain amount
of "Tokens" (the critter form of currency), and every action (like an
executed befunge instruction, a repeated command, a spawned thread,
etc) incurs a cost.  When the number of tokens drops to 0, the critter
dies.  This prevents the critter from getting itself (and the rest of
the system) into trouble.

For reference, the following things are specifically tested for:

=over 4

=item Size of stacks

=item Number of stacks

=item Storage size (electric fence)

=item Number of threads

=item "k" command repeat count

=item "j" command jump count

=item "x" command dead IP checks (setting a null vector)

=back

Most of the above things will result in spending some tokens.  There
are a couple of exceptions to this: a storage write outside the
confines of the critter's fence will result in the interpreter
crashing and the critter dying with it; similarly, a huge "j" jump
count will also kill the critter.

The following commands are removed entirely from the interpreter's Ops
hash:

    , (Output Character)
    . (Output Integer)
    ~ (Input Character)
    & (Input Integer)
    i (Input File)
    o (Output File)
    = (Execute)
    ( (Load Semantics)
    ) (Unload Semantics)


=head1 CONSTRUCTOR

=head2 new

    Critter->new(Blueprint => \$blueprint, Physics => \$physics,
              IterPerTurn => 10000, MaxThreads => 100, Config => \$config,\n"
              MaxStack => 1000,Color => 1, BoardSize => \$vector)";

Create a new Critter object.

The following arguments are required:

=over 4

=item Blueprint

The blueprint object, which contains the code for this critter.  Also
note, we also use the Blueprint object to cache a copy of the storage
object, to speed up creation of subsequent Critter objects.

=item Physics

The physics object controls the semantics of how the universe
operates.  Mainly it controls the size of the game board (if any).

=item Config

The config object, see L<AI::Evolve::Befunge::Util::Config>.

=item Tokens

Tokens are the basic form of life currency in this simulation. 
Critters have a certain amount of tokens at the beginning of a run
(controlled by this value), and they spend tokens to perform tasks.
(The amount of tokens required to perform a task depends on the
various "Cost" values, below.)

When the number of tokens reaches 0, the critter dies (and the
interpreter is killed).

=back


The following arguments are optional:

=over 4


=item CodeCost

This is the number of tokens the critter pays (up front, at birth
time) for the codespace it inhabits.  If the blueprint's CodeSize
is (8,8,8), 8*8*8 = 512 spaces are taken up.  If the CodeCost is 1,
that means the critter pays 512 tokens just to be born.  If CodeCost
is 2, the critter pays 1024 tokens, and so on.

If not specified, this will be pulled from the variable "codecost" in
the config file.  If that can't be found, a default value of 1 is
used.


=item IterCost

This is the number of tokens the critter pays for each command it
runs.  It is a basic operational overhead, decremented for each clock
tick for each running thread.

If not specified, this will be pulled from the variable "itercost" in
the config file.  If that can't be found, a default value of 2 is
used.


=item RepeatCost

This is the number of tokens the critter pays for each time a command
is repeated (with the "k" instruction).  It makes sense for this value
to be lower than the IterCost setting, as it is somewhat more
efficient.

If not specified, this will be pulled from the variable "repeatcost"
in the config file.  If that can't be found, a default value of 1 is
used.


=item StackCost

This is the number of tokens the critter pays for each time a value
is pushed onto the stack.  It also has an effect when the critter
creates a new stack; the number of stack entries to be copied is
multiplied by the StackCost to determine the total cost.

If not specified, this will be pulled from the variable "stackcost"
in the config file.  If that can't be found, a default value of 1 is
used.


=item ThreadCost

This is a fixed number of tokens the critter pays for spawning a new
thread.  When a new thread is created, this cost is incurred, plus the
cost of duplicating all of the thread's stacks (see StackCost, above).
The new threads will begin incurring additional costs from the
IterCost (also above), when it begins executing commands of its own.

If not specified, this will be pulled from the variable "threadcost"
in the config file.  If that can't be found, a default value of 10 is
used.


=item Color

This determines the color of the player, which (for board games)
indicates which type of piece the current player is able to play.  It
has no other effect, and thus, it is not necessary for non-boardgame
physics models.

If not specified, a default value of 1 is used.


=item BoardSize

If specified, a board game of the given size (specified as a Vector
object) is created.

=back

=cut

sub new {
    my $package = shift;
    my %args = (
        # defaults
        Color       => 1,
        @_
    );
    # args
    my $usage = 
      "Usage: $package->new(Blueprint => \$blueprint, Physics => \$physics,\n"
     ."                     Tokens => 2000, BoardSize => \$vector, Config => \$config)";
    croak $usage unless exists  $args{Config};
    $args{Tokens}     = $args{Config}->config('tokens'     , 2000) unless defined $args{Tokens};
    $args{CodeCost}   = $args{Config}->config("code_cost"  , 1   ) unless defined $args{CodeCost};
    $args{IterCost}   = $args{Config}->config("iter_cost"  , 2   ) unless defined $args{IterCost};
    $args{RepeatCost} = $args{Config}->config("repeat_cost", 1   ) unless defined $args{RepeatCost};
    $args{StackCost}  = $args{Config}->config("stack_cost" , 1   ) unless defined $args{StackCost};
    $args{ThreadCost} = $args{Config}->config("thread_cost", 10  ) unless defined $args{ThreadCost};

    croak $usage unless exists  $args{Blueprint};
    croak $usage unless exists  $args{Physics};
    croak $usage unless defined $args{Color};

    my $codelen = 1;
    foreach my $d ($args{Blueprint}->size->get_all_components) {
        $codelen *= $d;
    }
    croak "CodeCost must be greater than 0!"   unless $args{CodeCost}   > 0;
    croak "IterCost must be greater than 0!"   unless $args{IterCost}   > 0;
    croak "RepeatCost must be greater than 0!" unless $args{RepeatCost} > 0;
    croak "StackCost must be greater than 0!"  unless $args{StackCost}  > 0;
    croak "ThreadCost must be greater than 0!" unless $args{ThreadCost} > 0;
    $args{Tokens} -= ($codelen * $args{CodeCost});
    croak "Tokens must exceed the code size!"  unless $args{Tokens}     > 0;
    croak "Code must be freeform!  (no newlines)"
        if $args{Blueprint}->code =~ /\n/;

    my $self = bless({}, $package);
    $$self{blueprint}  = $args{Blueprint};
    $$self{boardsize}  = $args{BoardSize} if exists $args{BoardSize};
    $$self{code}       = $$self{blueprint}->code;
    $$self{codecost}   = $args{CodeCost};
    $$self{codesize}   = $$self{blueprint}->size;
    $$self{config}     = $args{Config};
    $$self{dims}       = $$self{codesize}->get_dims();
    $$self{itercost}   = $args{IterCost};
    $$self{repeatcost} = $args{RepeatCost};
    $$self{stackcost}  = $args{StackCost};
    $$self{threadcost} = $args{ThreadCost};
    $$self{tokens}     = $args{Tokens};
    if(exists($$self{boardsize})) {
        $$self{dims} = $$self{boardsize}->get_dims()
            if($$self{dims} < $$self{boardsize}->get_dims());
    }
    if($$self{codesize}->get_dims() < $$self{dims}) {
        # upgrade codesize (keep it hypercubical)
        $$self{codesize} = Language::Befunge::Vector->new(
            $$self{codesize}->get_all_components(),
            map { $$self{codesize}->get_component(0) }
                (1..$$self{dims}-$$self{codesize}->get_dims())
        );
    }
    if(exists($$self{boardsize})) {
        if($$self{boardsize}->get_dims() < $$self{dims}) {
            # upgrade boardsize
            $$self{boardsize} = Language::Befunge::Vector->new(
                $$self{boardsize}->get_all_components(),
                map { 1 } (1..$$self{dims}-$$self{boardsize}->get_dims())
            );
        }
    }

    $$self{color} = $args{Color};
    croak "Color must be greater than 0" unless $$self{color} > 0;
    $$self{physics} = $args{Physics};
    croak "Physics must be a reference" unless ref($$self{physics});
    
    # set up our corral to be twice the size of our code or our board, whichever
    # is bigger.
    my $maxpos = Language::Befunge::Vector->new_zeroes($$self{dims});
    foreach my $dim (0..$$self{dims}-1) {
        if(!exists($$self{boardsize})
         ||($$self{codesize}->get_component($dim) > $$self{boardsize}->get_component($dim))) {
            $maxpos->set_component($dim, $$self{codesize}->get_component($dim));
        } else {
            $maxpos->set_component($dim, $$self{boardsize}->get_component($dim));
        }
    }
    my $minpos = Language::Befunge::Vector->new_zeroes($$self{dims}) - $maxpos;
    my $maxlen = 0;
    foreach my $d (0..$$self{dims}-1) {
        my $this = $maxpos->get_component($d) - $minpos->get_component($d);
        $maxlen = $this if $this > $maxlen;
    }
    $$self{maxsize} = $maxpos;
    $$self{minsize} = $minpos;
    $$self{maxlen}  = $maxlen;

    my $interp = Language::Befunge::Interpreter->new({
        dims    => $$self{dims},
        storage => 'Language::Befunge::Storage::Generic::Vec'
    });
    $$self{interp} = $interp;
    $$self{codeoffset} = $minpos;
    my $cachename = "storagecache-".$$self{dims};
    if(exists($$self{blueprint}{cache})
    && exists($$self{blueprint}{cache}{$cachename})) {
        $$interp{storage} = $$self{blueprint}{cache}{$cachename}->_copy;
    } else {
        if($$self{dims} > 1) {
            # split code into lines, pages, etc as necessary.
            my @lines;
            my $meas = $$self{codesize}->get_component(0);
            my $dims = $$self{dims};
            my @terms = ("", "\n", "\f");
            push(@terms, "\0" x ($_-2)) for(3..$dims);

            push(@lines, substr($$self{code}, 0, $meas, "")) while length $$self{code};
            foreach my $dim (0..$dims-1) {
                my $offs = 1;
                $offs *= $meas for (1..$dim-1);
                for(my $i = $offs; $i <= scalar @lines; $i += $offs) {
                    $lines[$i-1] .= $terms[$dim];
                }
            }
            $$self{code} = join("", @lines);
        }

        $interp->get_storage->store($$self{code}, $$self{codeoffset});
        # assign our corral size to the befunge space
        $interp->get_storage->expand($$self{minsize});
        $interp->get_storage->expand($$self{maxsize});
        # save off a copy of this befunge space for later reuse
        $$self{blueprint}{cache} = {} unless exists $$self{blueprint}{cache};
        $$self{blueprint}{cache}{$cachename} = $interp->get_storage->_copy;
    }
    my $storage = $interp->get_storage;
    $$storage{maxsize} = $$self{maxsize};
    $$storage{minsize} = $$self{minsize};
    # store a copy of the Critter in the storage, so _expand (below) can adjust
    # the remaining tokens.
    $$storage{_ai_critter} = $self;
    weaken($$storage{_ai_critter});
    # store a copy of the Critter in the interp, so various command callbacks
    # (below) can adjust the remaining tokens.
    $$interp{_ai_critter} = $self;
    weaken($$interp{_ai_critter});

    $interp->get_ops->{'{'} = \&AI::Evolve::Befunge::Critter::_block_open;
    $interp->get_ops->{'j'} = \&AI::Evolve::Befunge::Critter::_op_flow_jump_to_wrap;
    $interp->get_ops->{'k'} = \&AI::Evolve::Befunge::Critter::_op_flow_repeat_wrap;
    $interp->get_ops->{'t'} = \&AI::Evolve::Befunge::Critter::_op_spawn_ip_wrap;

    my @invalid_meths = (',','.','&','~','i','o','=','(',')',map { chr } (ord('A')..ord('Z')));
    $$self{interp}{ops}{$_} = $$self{interp}{ops}{r} foreach @invalid_meths;

    if(exists($args{Commands})) {
        foreach my $command (sort keys %{$args{Commands}}) {
            my $cb = $args{Commands}{$command};
            $$self{interp}{ops}{$command} = $cb;
        }
    }


    my @params;
    my @vectors;
    push(@vectors, $$self{boardsize}) if exists $$self{boardsize};
    push(@vectors, $$self{maxsize}, $$self{codesize});
    foreach my $vec (@vectors) {
        push(@params, $vec->get_all_components());
        push(@params, 1) for($vec->get_dims()+1..$$self{dims});
    }
    push(@params, $$self{threadcost}, $$self{stackcost}, $$self{repeatcost}, 
         $$self{itercost}, $$self{tokens}, $$self{dims});
    push(@params, $self->physics->token) if defined $self->physics->token;

    $$self{interp}->set_params([@params]);

    return $self;
}


=head1 METHODS

=head2 invoke

    my $rv = $critter->invoke($board);
    my $rv = $critter->invoke();

Run through a life cycle.  If a board is specified, the board state
is copied into the appropriate place before execution begins.

This should be run within an "eval"; if the critter causes an
exception, it will kill this function.  It is commonly invoked by
L</move> (see below), which handles exceptions properly.

=cut

sub invoke {
    my ($self, $board) = @_;
    delete($$self{move});
    $self->populate($board) if defined $board;
    my $rv = Result->new(name => $self->blueprint->name);
    my $initial_ip = Language::Befunge::IP->new($$self{dims});
    $initial_ip->set_position($$self{codeoffset});
    my $interp = $self->interp;
    push(@{$initial_ip->get_toss}, @{$interp->get_params});
    $interp->set_ips([$initial_ip]);
    while($self->tokens > 0) {
        my $ip = shift @{$interp->get_ips()};
        unless(defined($ip)) {
            my @ips = @{$interp->get_newips};
            last unless scalar @ips;
            $ip = shift @ips;
            $interp->set_ips([@ips]);
        }
        unless(defined $$ip{_ai_critter}) {
            $$ip{_ai_critter} = $self;
            weaken($$ip{_ai_critter});
        }
        last unless $self->spend($self->itercost);
        $interp->set_curip($ip);
        $interp->process_ip();
        if(defined($$self{move})) {
            debug("move made: " . $$self{move} . "\n");
            $rv->choice( $$self{move} );
            return $rv;
        }
    }
    debug("play timeout\n");
    return $rv;
}


=head2 move

    my $rv = $critter->move($board, $score);

Similar to invoke(), above.  This function wraps invoke() in an
eval block, updates a scoreboard afterwards, and creates a "dead"
return value if the eval failed.

=cut

sub move {
    my ($self, $board) = @_;
    my $rv;
    local $@ = '';
    eval {
        $rv = $self->invoke($board);
    };
    if($@ ne '') {
        debug("eval error $@\n");
        $rv = Result->new(name => $self->blueprint->name, died => 1);
        my $reason = $@;
        chomp $reason;
        $rv->fate($reason);
    }
    $rv->tokens($self->tokens);
    return $rv;
}


=head2 populate

    $critter->populate($board);

Writes the board game state into the Befunge universe.

=cut

sub populate {
    my ($self, $board) = @_;
    my $storage = $$self{interp}->get_storage;
    $storage->store($board->as_string);
    $$self{interp}{_ai_board} = $board;
    weaken($$self{interp}{_ai_board});
}


=head2 spend

    return unless $critter->spend($tokens * $cost);

Attempts to spend a certain amount of the critter's tokens.  Returns
true on success, false on failure.

=cut

sub spend {
    my ($self, $cost) = @_;
    $cost = int($cost);
    my $tokens = $self->tokens - $cost;
    #debug("spend: cost=$cost resulting tokens=$tokens\n");
    return 0 if $tokens < 0;
    $self->tokens($tokens);
    return 1;
}


# sandboxing stuff
{
    no warnings 'redefine';

    # override Storage->expand() to impose bounds checking
    my $_lbsgv_expand;
    BEGIN { $_lbsgv_expand = \&Language::Befunge::Storage::Generic::Vec::expand; };
    sub _expand {
        my ($storage, $v) = @_;
        if(exists($$storage{maxsize})) {
            my $min = $$storage{minsize};
            my $max = $$storage{maxsize};
            die "$v is out of bounds [$min,$max]!\n"
                unless $v->bounds_check($min, $max);
        }
        my $rv = &$_lbsgv_expand(@_);
        return $rv;
    }
    # redundant assignment avoids a "possible typo" warning
    *Language::Befunge::Storage::Generic::Vec::XS::expand = \&_expand;
    *Language::Befunge::Storage::Generic::Vec::XS::expand = \&_expand;
    *Language::Befunge::Storage::Generic::Vec::expand     = \&_expand;

    # override IP->spush() to impose stack size checking
    my $_lbip_spush;
    BEGIN { $_lbip_spush = \&Language::Befunge::IP::spush; };
    sub _spush {
        my ($ip, @newvals) = @_;
        my $critter = $$ip{_ai_critter};
        return $ip->dir_reverse unless $critter->spend($critter->stackcost * scalar @newvals);
        my $rv = &$_lbip_spush(@_);
        return $rv;
    }
    *Language::Befunge::IP::spush = \&_spush;

    # override IP->ss_create() to impose stack count checking
    sub _block_open {
        my ($interp) = @_;
        my $ip       = $interp->get_curip;
        my $critter = $$ip{_ai_critter};
        my $count    = $ip->svalue(1);
        return $ip->dir_reverse unless $critter->spend($critter->stackcost * $count);
        return Language::Befunge::Ops::block_open(@_);
    }

    # override op_flow_jump_to to impose skip count checking
    sub _op_flow_jump_to_wrap {
        my ($interp) = @_;
        my $ip       = $interp->get_curip;
        my $critter  = $$interp{_ai_critter};
        my $count    = $ip->svalue(1);
        return $ip->dir_reverse unless $critter->spend($critter->repeatcost * abs($count));
        return Language::Befunge::Ops::flow_jump_to(@_);
    }

    # override op_flow_repeat to impose loop count checking
    sub _op_flow_repeat_wrap {
        my ($interp) = @_;
        my $ip       = $interp->get_curip;
        my $critter  = $$interp{_ai_critter};
        my $count    = $ip->svalue(1);
        return $ip->dir_reverse unless $critter->spend($critter->repeatcost * abs($count));
        return Language::Befunge::Ops::flow_repeat(@_);
    }

    # override op_spawn_ip to impose thread count checking
    sub _op_spawn_ip_wrap {
        my ($interp) = @_;
        my $ip       = $interp->get_curip;
        my $critter  = $$interp{_ai_critter};
        my $cost     = 0;$critter->threadcost;
        foreach my $stack ($ip->get_toss(), @{$ip->get_ss}) {
            $cost   += scalar @$stack;
        }
        $cost       *= $critter->stackcost;
        $cost       += $critter->threadcost;
        return $ip->dir_reverse unless $critter->spend($cost);
        # This is a hack; Storable can't deep copy our data structure.
        # It will get re-added to both parent and child, next time around.
        delete($$ip{_ai_critter});
        return Language::Befunge::Ops::spawn_ip(@_);
    }
}

1;
