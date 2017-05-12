#!perl -T

use strict;
use warnings;

use Test::More tests => 4 * 4 + 4 * 2;

use B::Deparse;
use B::RecDeparse;

my $bd_version = $B::Deparse::VERSION;
{
 local $@;
 $bd_version = eval $bd_version;
 die $@ if $@;
}

sub add ($$) { $_[0] + $_[1] }
sub mul { $_[0] * $_[1] }
sub fma { add mul($_[0], $_[1]), $_[2] }
sub wut { fma $_[0], 2, $_[1] }

my @bd_args = ('', '-sCi0v1');
my @brd_args = ({ }, { deparse => undef }, { deparse => { } }, { deparse => [ ] });

my $bd = B::Deparse->new();
my $reference = $bd->coderef2text(\&wut);
my $i = 1;
for (@brd_args) {
 my $brd = B::RecDeparse->new(%$_, level => 0);
 my $code = $brd->coderef2text(\&wut);
SKIP: {
 skip 'Harmless mismatch on "use warnings" code generation with olders B::Deparse' => 1 if $bd_version < 0.71;
 is($code, $reference, "empty deparse and level 0 does the same thing as B::Deparse ($i)");
}
 $code = eval 'sub ' . $code;
 is($@, '', "result compiles ($i)");
 is_deeply( [ defined $code, ref $code ], [ 1, 'CODE' ], "result compiles to a code reference ($i)");
 is($code->(1, 3), wut(1, 3), "result compiles to the good thing ($i)");
 ++$i;
}

my $bd_opts = '-sCi0v1';
@brd_args = ({ deparse => $bd_opts }, { deparse => [ $bd_opts ] });
for (@brd_args) {
 $bd = B::Deparse->new($bd_opts);
 my $brd = B::RecDeparse->new(%$_, level => 0);
 my $code = $brd->coderef2text(\&wut);
 is($code, $bd->coderef2text(\&wut), "B::RecDeparse->new(deparse => '$bd_opts' ), level => 0) does the same thing as B::Deparse->new('$bd_opts') ($i)");
 $code = eval 'sub ' . $code;
 is($@, '', "result compiles ($i)");
 is_deeply( [ defined $code, ref $code ], [ 1, 'CODE' ], "result compiles to a code reference ($i)");
 is($code->(1, 3), wut(1, 3), "result compiles to the good thing ($i)");
 ++$i;
}
