# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
use Benchmark ':all';
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 125;
BEGIN { use_ok('Algorithm::LCS::XS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Algorithm::LCS::XS qw/ADLCS LCSidx/;
use Algorithm::Diff;
use POSIX 'dup2';
dup2 fileno(STDERR), fileno(STDOUT);

my @a = (qw/aaaaaaaaa bbbbbbbbb ddddddddd ccccccccc eeeeeeeee fffffffff/) x 10;
my @b = (qw/aaaaaaaaa ccccccccc ddddddddd bbbbbbbbb eeeeeeeee fffffffff/) x 10;

$|++;


my $alg = Algorithm::LCS::XS->new;
my @lcs = $alg->LCS(\@a, \@b);

ok @lcs == 40;
ok $a[$lcs[$_][0]] eq $b[$lcs[$_][1]] for 0..39;

my $cb = $alg->callback(@b);

my @lcs2 = $cb->(\@a);
ok @lcs2 == 40;
ok $a[$lcs2[$_][0]] eq $b[$lcs2[$_][1]] for 0..39;

my $ad_lcsidx = sub { Algorithm::Diff::LCSidx(\@a, \@b) };
my $ad_lcs = sub {Algorithm::Diff::LCS(\@a, \@b) };
my $my_xs_lcs = sub { $alg->LCS(\@a, \@b) };
my $my_xs_cb = sub { $cb->(\@a) };
my $my_adlcs = sub { ADLCS(\@a, \@b) };
my $my_lcsidx = sub {LCSidx(\@a, \@b) };

my ($l, $r) = $my_lcsidx->();
ok @$l == @$r;
ok @$l == 40;
ok $a[$l[$_]] eq $b[$r[$_]] for 0..39;

use LCS::BV;
my $obj = LCS::BV->new;
my $positions = $obj->prepare(\@a);

my $bv_llcs = sub { $obj->LLCS_prepared($positions, \@b) };
my $bv_lcs = sub { $obj->LCS(\@a, \@b) };

use LCS::XS;

my $alg2 = LCS::XS->new;
my $lcs_xs = sub { $alg2->LCS(\@a, \@b) };

cmpthese 100_000 => { ad_lcsidx => $ad_lcsidx, ad_lcs => $ad_lcs, my_adlcs => $my_adlcs, my_lcsidx => $my_lcsidx, my_xs_cb => $my_xs_cb, bv_lcs => $bv_lcs, bv_llcs => $bv_llcs, lcs_xs => $lcs_xs };
