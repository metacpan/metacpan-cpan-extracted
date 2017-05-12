#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN { $ENV{AIEVOLVEBEFUNGE} = 't/insane.conf'; };

use aliased 'AI::Evolve::Befunge::Blueprint' => 'Blueprint';
use aliased 'AI::Evolve::Befunge::Critter'   => 'Critter';
use AI::Evolve::Befunge::Util qw(v custom_config push_debug);

my $num_tests;
BEGIN { $num_tests = 0; };


# setup
my $ph = AI::Evolve::Befunge::Physics->new('test1');
my $bp = Blueprint->new(code => ' 'x256, dimensions => 4);
my $bp2 = Blueprint->new(code => " \n"x128, dimensions => 4);
my $config = custom_config();


# constructor
dies_ok(sub {Critter->new(Config => $config, Physics => $ph)}, "Critter->new dies without Blueprint");
like($@, qr/Usage: /, "died with usage message");
dies_ok(sub {Critter->new(Blueprint => $bp, Physics => $ph                    )}, "Critter->new dies without Config");
dies_ok(sub {Critter->new(Blueprint => $bp, Config => $config                )}, "Critter->new dies without Physics");
dies_ok(sub {Critter->new(Blueprint => $bp, Physics => 1,   Config => $config)}, "Critter->new dies with 0 non-ref Physics");
lives_ok(sub{Critter->new(Blueprint => $bp, Physics => $ph, Config => $config)}, "Critter->new lives ok with normal args");
my @common_args = (Blueprint => $bp, Physics => $ph, Config => $config);
dies_ok(sub {Critter->new(@common_args, Color       => undef)}, "Critter->new dies with undef Color");
dies_ok(sub {Critter->new(@common_args, Tokens      => 0)}, "Critter->new dies with 0 Tokens");
dies_ok(sub {Critter->new(@common_args, CodeCost    => 0)}, "Critter->new dies with 0 CodeCost");
dies_ok(sub {Critter->new(@common_args, IterCost    => 0)}, "Critter->new dies with 0 IterCost");
dies_ok(sub {Critter->new(@common_args, RepeatCost  => 0)}, "Critter->new dies with 0 RepeatCost");
dies_ok(sub {Critter->new(@common_args, StackCost   => 0)}, "Critter->new dies with 0 StackCost");
dies_ok(sub {Critter->new(@common_args, ThreadCost  => 0)}, "Critter->new dies with 0 ThreadCost");
dies_ok(sub {Critter->new(@common_args, Color       => 0)}, "Critter->new dies with 0 Color");
dies_ok(sub {Critter->new(Blueprint => $bp2,Physics => $ph, Config => $config)}, "Critter->new dies with newlines in code");
$bp2 = Blueprint->new(code => "00M", dimensions => 1);
lives_ok(sub{Critter->new(Blueprint => $bp2,Physics => $ph, Config => $config)}, "Critter->new handles unefunge");
my $critter = Critter->new(
    Blueprint => $bp,
    Physics   => $ph,
    Config    => $config,
    BoardSize => v(3, 3),
);
ok(ref($critter) eq "AI::Evolve::Befunge::Critter", "create a critter object");
is($critter->dims, 4, "codesize->dims > boardsize->dims, codesize->dims is used");
$critter = Critter->new(
    Blueprint => $bp2,
    Physics   => $ph,
    Config    => $config,
    BoardSize => v(3, 3),
    Commands  => { M => sub { AI::Evolve::Befunge::Physics::op_make_board_move(@_) } },
    IterPerTurn => 100,
);
is($critter->dims, 2, "codesize->dims < boardsize->dims, boardsize->dims is used");
BEGIN { $num_tests += 19 };


# invoke
my $board = AI::Evolve::Befunge::Board->new(Size => v(3, 3));
lives_ok(sub { $critter->invoke($board) }, "invoke runs with board");
lives_ok(sub { $critter->invoke()       }, "invoke runs without board");
$bp2 = Blueprint->new(code => "999**kq", dimensions => 1);
$critter = Critter->new(
    Blueprint => $bp2,
    Physics   => $ph,
    Config    => $config,
    BoardSize => v(3, 3),
    Commands  => { M => sub { AI::Evolve::Befunge::Physics::op_make_board_move(@_) } },
    IterPerTurn => 100,
);
my $rv = $critter->move();
is($rv->tokens, 1242, "repeat count is accepted");

$critter = Critter->new(
    Blueprint => $bp2,
    Physics   => $ph,
    Config    => $config,
    BoardSize => v(3, 3),
    Tokens    => 500,
    Commands  => { M => sub { AI::Evolve::Befunge::Physics::op_make_board_move(@_) } },
    IterPerTurn => 100,
);
$rv = $critter->move();
is($rv->tokens, 449, "repeat count is rejected");

$bp2 = Blueprint->new(code => "    ", dimensions => 1);
$critter = Critter->new(
    Blueprint => $bp2,
    Physics   => $ph,
    Config    => $config,
    BoardSize => v(3, 3),
    Commands  => { M => sub { AI::Evolve::Befunge::Physics::op_make_board_move(@_) } },
    IterPerTurn => 100,
);
$rv = $critter->move();
ok($rv->died, "critter died");
like($rv->fate, qr/infinite loop/, "infinite loop is detected");

$critter = Critter->new(
    Blueprint => $bp,
    Physics   => $ph,
    Config    => $config,
    Commands  => AI::Evolve::Befunge::Physics::find_physics("test1")->{commands},
);
BEGIN { $num_tests += 6 };


# Critter's nerfed Language::Befunge interpreter
ok(exists($$critter{interp}{ops}{'+'}), "Language::Befunge loaded");
foreach my $op (',','.','&','~','i','o','=','(',')') {
    is($$critter{interp}{ops}{$op}, $$critter{interp}{ops}{r}, "operator $op got removed");
}
BEGIN { $num_tests += 10 };
foreach my $op ('+','-','1','2','3','<','>','[',']') {
    isnt($$critter{interp}{ops}{$op}, $$critter{interp}{ops}{r}, "operator $op wasn't removed");
}
BEGIN { $num_tests += 9 };


# Critter adds extra commands specified by physics engine
is($$critter{interp}{ops}{T},
    AI::Evolve::Befunge::Physics::find_physics("test1")->{commands}{T},
    "'Test' command added");
is  ($$critter{interp}{ops}{M}, $$critter{interp}{ops}{r}, "'Move' command not added");
BEGIN { $num_tests += 2 };


sub newaebc {
    my ($code, $fullsize, $nd, @extra) = @_;
    $code .= ' 'x($fullsize-length($code)) if length($code) < $fullsize;
    my $bp = Blueprint->new(code => $code, dimensions => $nd);
    push(@extra, BoardSize => $ph->board_size) if defined $ph->board_size;
    my $rv = Critter->new(Blueprint => $bp, Config => $config, Physics => $ph, 
        Commands  => AI::Evolve::Befunge::Physics::find_physics("test1")->{commands},
        @extra);
    return $rv;
}


# Critter adds lots of useful info to the initial IP's stack
my $stack_expectations =
    [ord('P'), # physics plugin
     2,        # dimensions
     1983,     # tokens
     2,        # itercost
     1,        # repeatcost
     2,        # stackcost
     10,       # threadcost
     17, 17,   # codesize
     17, 17,   # maxsize
     5, 5,     # boardsize,
     ];
$rv = newaebc('PPPPPPPPPPPPPPPPq', 17, 1);
is_deeply([reverse @{$rv->interp->get_params}], $stack_expectations, 'Critter constructor sets the params value correctly');
push(@$stack_expectations, 0, 0, 0); # make sure nothing else is on the stack
$rv = $rv->move();
ok(!$rv->died, "did not die");
is_deeply([@AI::Evolve::Befunge::Physics::test1::p], $stack_expectations, 'Critter adds lots of useful info to the initial stack');
@AI::Evolve::Befunge::Physics::test1::p = ();
$rv = newaebc('PPPPPPPPPPPPPPPPq', 17, 1)->move();
ok(!$rv->died, "did not die");
is_deeply([@AI::Evolve::Befunge::Physics::test1::p], $stack_expectations, 'Critter adds it EVERY time');
BEGIN { $num_tests += 5 };


$rv = newaebc("aq", 2, 1, Tokens => 60, StackCost => 40)->move();
is($rv->tokens, 14, 'spush decremented the proper amount');
ok(!$rv->died, "did not die");
$rv = newaebc("aq", 2, 1, Tokens => 30, StackCost => 40)->move();
is($rv->tokens, 24, 'spush bounced');
ok(!$rv->died, "did not die");
BEGIN { $num_tests += 4 };


$rv = newaebc("9{q", 3, 1, Tokens => 50, StackCost => 4)->move();
is($rv->tokens, 1, 'block_open decremented the proper amount');
ok(!$rv->died, "did not die");
$rv = newaebc("9{q", 3, 1, Tokens => 30, StackCost => 4)->move();
is($rv->tokens, 11, 'block_open bounced');
ok(!$rv->died, "did not die");
BEGIN { $num_tests += 4 };


$rv = newaebc("1jzq", 4, 1, Tokens => 250, RepeatCost => 200)->move();
is($rv->tokens, 38, '_op_flow_jump_to_wrap decremented the proper amount');
ok(!$rv->died, "did not die");
$rv = newaebc("1jzq", 4, 1, Tokens =>  50, RepeatCost => 200)->move();
is($rv->tokens, 34, '_op_flow_jump_to_wrap bounced');
ok(!$rv->died, "did not die");
BEGIN { $num_tests += 4 };


$rv = newaebc("ak1q", 4, 1, Tokens => 150, RepeatCost => 10)->move();
is($rv->tokens, 14, '_op_flow_repeat_wrap decremented the proper amount');
ok(!$rv->died, "did not die");
$rv = newaebc("ak1q", 4, 1, Tokens => 50, RepeatCost => 10)->move();
is($rv->tokens, 34, '_op_flow_repeat_wrap bounced');
ok(!$rv->died, "did not die");
BEGIN { $num_tests += 4 };


$rv = newaebc("tq", 2, 1, Tokens => 50, ThreadCost => 10);
$rv = $rv->move();
is($rv->tokens, 8, '_op_spawn_ip_wrap decremented the proper amount');
ok(!$rv->died, "did not die");
$rv = newaebc("tq", 2, 1, Tokens => 10, ThreadCost => 10)->move();
is($rv->tokens, 4, '_op_spawn_ip_wrap bounced');
ok(!$rv->died, "did not die");
BEGIN { $num_tests += 4 };


# as a side effect, this also verifies that M, a non-defined command,
# acts like "r" (reverse).
is($AI::Evolve::Befunge::Physics::test1::t, 0, "T command not called before");
$rv = newaebc("1T1MqT5", 7, 1, Tokens => 50)->move();
ok(!$rv->died, "did not die");
is($AI::Evolve::Befunge::Physics::test1::t, 7, "T command had expected effect");
BEGIN { $num_tests += 3 };


my $befunge = $$critter{interp};
my $ls = $befunge->get_storage;
lives_ok{$ls->expand(v(4, 4, 4, 4))} "expand bounds checking";
dies_ok {$ls->expand(v(4, 4, 4, 5))} "expand bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
dies_ok {$ls->expand(v(4, 4, 5, 4))} "expand bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
dies_ok {$ls->expand(v(4, 5, 4, 4))} "expand bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
dies_ok {$ls->expand(v(5, 4, 4, 4))} "expand bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
lives_ok{$ls->expand(v(-4,-4,-4,-4))} "set_min bounds checking";
dies_ok {$ls->expand(v(-4,-4,-4,-5))} "set_min bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
dies_ok {$ls->expand(v(-4,-4,-5,-4))} "set_min bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
dies_ok {$ls->expand(v(-4,-5,-4,-4))} "set_min bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
dies_ok {$ls->expand(v(-5,-4,-4,-4))} "set_min bounds checking";
like($@, qr/out of bounds/, "out of bounds detection");
BEGIN { $num_tests += 18 };


BEGIN { plan tests => $num_tests };


package AI::Evolve::Befunge::Physics::test1;
use strict;
use warnings;
use Carp;
use aliased 'Language::Befunge::Vector' => 'LBV';

our $t;
our @p;
BEGIN { $t = 0 };

use base 'AI::Evolve::Befunge::Physics';
use AI::Evolve::Befunge::Physics qw(register_physics);
use AI::Evolve::Befunge::Util qw(v);

sub new {
    my $package = shift;
    return bless({}, $package);
}

sub setup_board {
    my ($self, $board) = @_;
    $board->clear();
}

sub valid_move {
    my ($self, $board, $player, $x, $y) = @_;
    return 0 if $board->fetch_value($x, $y);
    return 1;
}

sub won   { return 0; }
sub over  { return 0; }
sub score { return 0; }

sub make_move {
    my ($self, $board, $player, $x, $y) = @_;
    confess "make_move: player value '$player' out of range!" if $player < 1 or $player > 2;
    confess "make_move: x value is undef!" unless defined $x;
    confess "make_move: y value is undef!" unless defined $y;
    confess "make_move: x value '$x' out of range!" if $x < 0 or $x >= $$board{sizex};
    confess "make_move: y value '$y' out of range!" if $y < 0 or $y >= $$board{sizey};
    $board->set_value($x, $y, $player);
    return 0 if $self->won($board); # game over, one of the players won
    return 3-$player;
}

BEGIN {
    register_physics(
        name       => "test1",
        token      => ord('P'),
        board_size => v(5, 5),
        commands   => {
            T => sub { my $i = shift; my $j = $i->get_curip->spop; $t += $j },
            P => sub { my $i = shift; my $j = $i->get_curip->spop; push(@p, $j) },
        },
    );
};


1;
