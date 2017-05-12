package AI::Evolve::Befunge::Physics;
use strict;
use warnings;
use Carp;
use Perl6::Export::Attrs;
use UNIVERSAL::require;

use AI::Evolve::Befunge::Util;
use aliased 'AI::Evolve::Befunge::Board'           => 'Board';
use aliased 'AI::Evolve::Befunge::Critter'         => 'Critter';
use aliased 'AI::Evolve::Befunge::Critter::Result' => 'Result';

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw{ name board_size commands token decorate generations } );

# FIXME: this module needs some extra codepaths to handle non-boardgame Physics
# engines.

=head1 NAME

    AI::Evolve::Befunge::Physics - Physics engine base class

=head1 SYNOPSIS

For a rules plugin (game or application):

    register_physics(
        name       => "ttt",
        token      => ord('T'),
        decorate   => 0.
        board_size => Language::Befunge::Vector->new(3, 3),
        commands   => { M => \&AI::Evolve::Befunge::Physics::op_board_make_move },
    );

For everyone else:

    $ttt = Physics->new('ttt');
    my $score = $ttt->double_match($blueprint1, $blueprint2);


=head1 DESCRIPTION

This module serves a double purpose.

First, it serves as a plugin repository for Physics engines.  It
allows physics engines to register themselves, and it allows callers
to fetch entries from the database (indexed by the name of the Physics
engine).

Second, it serves as a base class for Physics engines.  It creates
class instances to represent a Physics engine, and given a blueprint
or two, allows callers to run creatures in a universe which follow the
rules of that Physics engine.


=head1 STANDALONE FUNCTIONS

=head2 register_physics

    register_physics(
        name       => "ttt",
        token      => ord('T'),
        decorate   => 0.
        board_size => Language::Befunge::Vector->new(3, 3),
        commands   => { M => \&AI::Evolve::Befunge::Physics::op_board_make_move },
    );

Create a new physics plugin, and register it with the Physics plugin
database.  The "name" passed here can be used later on in ->new()
(see below) to fetch an instance of that physics plugin.

The arguments are:

    name:       The name of the Physics module.  Used by Physics->new
                to fetch the right plugin.
    token:      A unique numeric token representing this Physics
                plugin.  It is possible that a Critter could evolve
                that can function usefully in more than one universe;
                this token is pushed onto its initial stack in order
                to encourage this.
    decorate:   Used by graphical frontends.  If non-zero, the
                graphical frontend will use special icons to indicate
                spaces where a player may move.
    commands:   A hash of op callback functions, indexed on the
                Befunge character that should call them.
    board_size: A Vector denoting the size of a game's board.  This
                field is optional; non-game plugins should leave it
                unspecified.


=cut

{ my %rules;

    sub register_physics :Export(:DEFAULT) {
        my %args = @_;
        croak("no name given")      unless exists $args{name};
        croak("Physics plugin '".$args{name}."' already registered!\n") if exists($rules{$args{name}});
        $rules{$args{name}} = \%args;
    }


=head2 find_physics

    my $physics = find_physics($name);

Find a physics plugin in the database.  Note that this is for internal
use; external users should use ->new(), below.

=cut

    sub find_physics {
        my $name = shift;
        return undef unless exists $rules{$name};
        return $rules{$name};
    }

}


=head1 CONSTRUCTOR

=head2 new

    my $physics = Physics->new('ttt');

Fetch a class instance for the given physics engine.  The argument
passed should be the name of a physics engine... for instance, 'ttt'
or 'othello'.  The physics plugin should be in a namespace under
'AI::Evolve::Befunge::Physics'... the module will be loaded if
necessary.

=cut

sub new {
    my ($package, $physics) = @_;
    my $usage = 'Usage: Physics->new($physicsname);';
    croak($usage) unless defined($package);
    croak($usage) unless defined($physics);
    my $module = 'AI::Evolve::Befunge::Physics::' . $physics;
    $module->require;
    my $rv = find_physics($physics);
    croak("no such physics module found") unless defined $rv;
    $rv = {%$rv}; # copy of the original object
    return bless($rv, $module);
}


=head1 METHODS

Once you have obtained a class instance by calling ->new(), you may
call the following methods on that instance.

=head2 run_board_game

    my $score = $physics->run_board_game([$critter1,$critter2],$board);

Run the two critters repeatedly, so that they can make moves in a
board game.

A score value is returned.  If a number greater than 0 is returned,
the critter wins.  If a number less than 0 is returned, the critter
loses.

The score value is derived in one of several ways... first priority
is to bias toward a creature which won the game, second is to bias
toward a creature who did not die (when the other did), third,
the physics plugin is asked to score the creatures based on the moves
they made, and finally, a choice is made based on the number of
resources each critter consumed.


=cut

sub run_board_game {
    my ($self, $aref, $board) = @_;
    my $usage = 'Usage: $physics->run_board_game([$critter1, $critter2], $board)';
    croak($usage) unless ref($self) =~ /^AI::Evolve::Befunge::Physics/;
    croak($usage) unless ref($board) eq 'AI::Evolve::Befunge::Board';
    my ($critter1, $critter2) = @$aref;
    croak($usage) unless ref($critter1) eq 'AI::Evolve::Befunge::Critter';
    croak($usage) unless ref($critter2) eq 'AI::Evolve::Befunge::Critter';
    croak($usage) if @$aref != 2;
    croak($usage) if @_ > 3;
    my $moves = 1;
    $self->setup_board($board);
    my @orig_players = ({critter => $critter1, stats => {pass => 0}},
                   {critter => $critter2, stats => {pass => 0}});
    my @players = @orig_players;
    # create a dummy Result object, just in case the loop never gets to player2
    # (because player1 died on the first move).
    $players[1]{rv} = Result->new(name => $critter2->blueprint->name, tokens => $critter2->tokens);
    while(!$self->over($board)) {
        my $rv = $players[0]{rv} = $players[0]{critter}->move($board, $players[0]{stats});
        my $move = $rv->choice();
        undef $move unless ref($move) eq 'Language::Befunge::Vector';
        if(!defined($move)) {
            if($self->can_pass($board,$players[0]{critter}->color())) {
                $players[0]{rv}->moves($moves);
            } else {
                if($rv->died) {
                    verbose("player ", $players[0]{critter}->color(), " died.\n");
                } else {
                    $rv->died(0.5);
                    $rv->fate('conceded');
                    verbose("player ", $players[0]{critter}->color(), " conceded.\n");
                }
                last;
            }
        }
        $moves++;
        $self->make_move($board, $players[0]{critter}->color(), $move) if defined $move;
        # swap players
        my $player = shift @players;
        push(@players,$player);
    }

    $board->output() unless get_quiet();

    # tally up the results to feed to compare(), below.
    my ($rv1   , $rv2   ) = ($orig_players[0]{rv}   , $orig_players[1]{rv}   );
    my ($stats1, $stats2) = ($orig_players[0]{stats}, $orig_players[1]{stats});
    $rv1->stats($stats1);
    $rv2->stats($stats2);
    $rv1->won(1) if $self->won($board) == $critter1->color();
    $rv2->won(1) if $self->won($board) == $critter2->color();
    $rv1->score($self->score($board, $critter1->color, $moves));
    $rv2->score($self->score($board, $critter2->color, $moves));
    return $self->compare($rv1, $rv2);
}


=head2 compare

    $rv = $physics->compare($rv1, $rv2);

Given two return values (as loaded up by the L</run_board_game>
method, above), return a comparison value for the critters they belong
to.  This is essentially a "$critter1 <=> $critter2" comparison; a
return value below 0 indicates that critter1 is the lesser of the two
critters, and a return value above 0 indicates that critter1 is the
greater of the two critters.  The following criteria will be used for
comparison, in decreasing order of precedence:

=over 4

=item The one that won

=item The one that didn't die

=item The one that scored higher

=item The one that made more moves

=item The one that had more tokens afterwards

=item The one with a greater (asciibetical) name

=back

=cut

# This is essentially a big $critter1 <=> $critter2 comparator.
sub compare {
    my ($self, $rv1, $rv2) = @_;
    my $rv;
    $rv = ($rv1->won()    <=> $rv2->won()   )*32; #    prefer more winning
    $rv = ($rv1->score()  <=> $rv2->score() )*16  # or prefer more scoring
        unless $rv;
    $rv = ($rv1->moves()  <=> $rv2->moves() )*8   # or prefer more moves
        unless $rv;
    $rv = ($rv1->tokens() <=> $rv2->tokens())*4   # or prefer more tokens
        unless $rv;
    $rv = ($rv2->died()   <=> $rv1->died()  )*2   # or prefer less dying
        unless $rv;
    $rv = ($rv2->name()   cmp $rv1->name()  )*1   # or prefer quieter names
        unless $rv;
    return $rv;
}


=head2 setup_and_run_board_game

    my $score = $physics->setup_and_run_board_game($bp1, $bp2);

Creates Critter objects from the given Blueprint objects, creates a
game board (with board_size as determined from the physics plugin),
and calls run_board_game, above.

=cut

sub setup_and_run_board_game {
    my ($self, $config, $bp1, $bp2) = @_;
    my $usage = '...->setup_and_run($config, $blueprint1, $blueprint2)';
    croak($usage) unless ref($config) eq 'AI::Evolve::Befunge::Util::Config';
    croak($usage) unless ref($bp1)    eq 'AI::Evolve::Befunge::Blueprint';
    croak($usage) unless ref($bp2)    eq 'AI::Evolve::Befunge::Blueprint';
    my @extra_args;
    push(@extra_args, Config    => $config);
    push(@extra_args, Physics   => $self);
    push(@extra_args, Commands  => $$self{commands});
    push(@extra_args, BoardSize => $self->board_size);
    my $board = Board->new(Size => $self->board_size);
    my $critter1 = Critter->new(Blueprint => $bp1, Color => 1, @extra_args);
    my $critter2 = Critter->new(Blueprint => $bp2, Color => 2, @extra_args);

    return $self->run_board_game([$critter1,$critter2], $board);
}


=head2 double_match

    my $relative_score = $physics->double_match($bp1, $bp2);

Runs two board games; one with bp1 starting first, and again with
bp2 starting first.  The second result is subtracted from the first,
and the result is returned.  This represents a qualitative comparison
between the two creatures.  This can be used as a return value for
mergesort or qsort.

=cut

sub double_match :Export(:DEFAULT) {
    my ($self, $config, $bp1, $bp2) = @_;
    my $usage = '...->double_match($config, $blueprint1, $blueprint2)';
    croak($usage) unless ref($config) eq 'AI::Evolve::Befunge::Util::Config';
    croak($usage) unless ref($bp1)    eq 'AI::Evolve::Befunge::Blueprint';
    croak($usage) unless ref($bp2)    eq 'AI::Evolve::Befunge::Blueprint';
    my ($data1, $data2);
    $data1 = $self->setup_and_run_board_game($config,$bp1,$bp2);
    $data2 = $self->setup_and_run_board_game($config,$bp2,$bp1);
    return ($data1 - $data2) <=> 0;
}


=head1 COMMAND CALLBACKS

These functions are intended for use as Befunge opcode handlers, and
are used by the Physics plugin modules.

=head2 op_make_board_move

    01M

Pops a vector (of the appropriate dimensions for the given board, not
necessarily the same as the codesize) from the stack, and attempts
to make that "move".  This is for Physics engines which represent
board games.

=cut

sub op_make_board_move {
    my ($interp)= @_;
    my $critter = $$interp{_ai_critter};
    my $board   = $$interp{_ai_board};
    my $color   = $$critter{color};
    my $physics = $$critter{physics};
    my $vec     = v($interp->get_curip->spop_mult($board->size->get_dims()));
    return Language::Befunge::Ops::dir_reverse(@_)
        unless $physics->valid_move($board, $color, $vec);
    $$critter{move} = $vec;
}

=head2 op_query_tokens

    T

Query the number of remaining tokens.

=cut

sub op_query_tokens {
    my ($interp)= @_;
    my $critter = $$interp{_ai_critter};
    $interp->get_curip->spush($critter->tokens);
}

1;
