# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20-mpi.t'

#########################

use Test;
BEGIN { plan tests => 39 }; # <--- number of tests
use ExtUtils::testlib;
use Crypt::GCrypt::MPI;

#########################


my $empty = Crypt::GCrypt::MPI->new(); # make simple MPI (defaults to zero?)
ok(defined $empty);
my $thirtysix = Crypt::GCrypt::MPI->new(36); # make simple MPI with integer assignment
ok(defined $thirtysix);
my $minusforty = Crypt::GCrypt::MPI->new(-40); # make simple MPI with negative integer assignment
ok(defined $minusforty);
my $zero = Crypt::GCrypt::MPI->new(0);
ok(defined $zero);

ok($empty->set($zero)->cmp($zero) == 0);
ok($zero->cmp($thirtysix) < 0);
ok($thirtysix->cmp($zero) > 0);

ok($zero->cmp($minusforty) > 0);
ok($minusforty->cmp($zero) < 0);

ok($thirtysix->cmp($minusforty) > 0);
ok($minusforty->cmp($thirtysix) < 0);

ok(!$zero->is_secure());

# basic test calculations:
my $x = Crypt::GCrypt::MPI->new(29);
$x->add(Crypt::GCrypt::MPI->new(7));
ok(0 == $x->cmp($thirtysix));
$x->mul(Crypt::GCrypt::MPI->new(-1));
$x->sub(Crypt::GCrypt::MPI->new(4));
ok(0 == $x->cmp($minusforty));

# modulo calculations:
$x = Crypt::GCrypt::MPI->new(29);
$x->addm(Crypt::GCrypt::MPI->new(12), $thirtysix);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(5)));
$x->subm(Crypt::GCrypt::MPI->new(60), $thirtysix);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(17)));
$x->mulm(Crypt::GCrypt::MPI->new(25), $thirtysix);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(29)));

$x->mul_2exp(6);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(1856)));

my $twentysix = Crypt::GCrypt::MPI->new(26);
my $y = Crypt::GCrypt::MPI->new(1856);

$x->mod($twentysix);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(10)));

$y->div($twentysix);
ok(0 == $y->cmp(Crypt::GCrypt::MPI->new(71)));


# powm, invm, gcd:
$x = Crypt::GCrypt::MPI->new(84);
$y = Crypt::GCrypt::MPI->new(24);
$y->gcd($x);
ok(0 == $y->cmp(Crypt::GCrypt::MPI->new(12)));

$x = Crypt::GCrypt::MPI->new(17);
my $z = Crypt::GCrypt::MPI->new(7);
$y->powm($z, $x);
ok(0 == $y->cmp(Crypt::GCrypt::MPI->new(7)));

$x = Crypt::GCrypt::MPI->new(12);
$y = Crypt::GCrypt::MPI->new(17);
$x->invm($y);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(10)));

ok("0a" eq unpack('H*', $x->print(Crypt::GCrypt::MPI::FMT_STD)));
ok("0A" eq $x->print(Crypt::GCrypt::MPI::FMT_HEX));
ok("0a" eq unpack('H*', $x->print(Crypt::GCrypt::MPI::FMT_USG)));

$x = Crypt::GCrypt::MPI->new(pack('H*', '0a0a'));
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(2570)));

$x = Crypt::GCrypt::MPI->new(value => pack('H*', '00000003010002'),
                             format => Crypt::GCrypt::MPI::FMT_SSH);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(65538)));

$x = Crypt::GCrypt::MPI->new(value => pack('H*', '0011010001'),
                             format => Crypt::GCrypt::MPI::FMT_PGP);
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(65537)));

# test copy constructor:
$y = Crypt::GCrypt::MPI->new($x);
ok(0 == $y->cmp($x));
$y->sub($thirtysix);
ok(0 == $y->cmp(Crypt::GCrypt::MPI->new(65501)));
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(65537)));

# test copy method:
$y = $x->copy();
ok(0 == $y->cmp($x));
$y->sub($thirtysix);
ok(0 == $y->cmp(Crypt::GCrypt::MPI->new(65501)));
ok(0 == $x->cmp(Crypt::GCrypt::MPI->new(65537)));

{ my $a = $y;
 $a->sub($thirtysix);
};

$y->sub($thirtysix);

ok(0 == $y->cmp(Crypt::GCrypt::MPI->new(65429)));

$x = Crypt::GCrypt::MPI->new(15);
$y = Crypt::GCrypt::MPI->new(16);
$z = Crypt::GCrypt::MPI->new(3);
ok($x->mutually_prime($y));
ok($y->mutually_prime($z));
ok(!$x->mutually_prime($z));
