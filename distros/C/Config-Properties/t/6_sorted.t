use Test::More tests => 8;

use Config::Properties;
use File::Temp qw(tempfile);

my $cfg=Config::Properties->new();
$cfg->load(\*DATA);

my ($fh, $fn)=tempfile()
    or die "unable to create temporal file to save properties";

$cfg->deleteProperty('dos');
$cfg->setProperty('cinco', '5');
$cfg->setProperty('tres', '6!');

$cfg->store($fh, "test header");
ok(close($fh), "config write");
open CFG, '<', $fn
    or die "unable to open tempory file $fn";

undef $/;
$contents=<CFG>;
ok(close(CFG), "config read");

# print STDERR "$fn\n$contents\n";

ok($contents=~/uno.*tres.*cuatro.*cinco/s,
   "order preserved");

unlink $fn;

ok((not -e $fn), "delete test file");

($fh, $fn)=tempfile()
    or die "unable to create temporal file to save properties";

$cfg->order('alpha');

$cfg->store($fh, "test header");
ok(close($fh), "config write");
open CFG, '<', $fn
    or die "unable to open tempory file $fn";

undef $/;
$contents=<CFG>;
ok(close(CFG), "config read");

# print STDERR "$fn\n$contents\n";

ok($contents=~/cinco.*cuatro.*tres.*uno/s,
   "alpha order preserved");

unlink $fn;

ok((not -e $fn), "delete test file");

__DATA__

uno = 1u
dos = 2u
tres = 3u
cuatro = 4u

