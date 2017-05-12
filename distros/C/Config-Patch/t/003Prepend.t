######################################################################
# Test suite for Config::Patch
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;

use Test::More tests => 3;
use Config::Patch;

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $TDIR = ".";
$TDIR = "t" if -d "t";
my $TESTFILE = "$TDIR/testfile";

END { unlink $TESTFILE; }

BEGIN { use_ok('Config::Patch') };

my $TESTDATA = "abc\ndef\nghi\n";

####################################################
# Single patch with prepend
####################################################
Config::Patch->blurt($TESTDATA, $TESTFILE);

my $patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "foobarkey");

$patcher->prepend(<<'EOT');
This is
a patch.
EOT

my $shouldbe = <<'EOT';
#(Config::Patch-foobarkey-prepend)
This is
a patch.
#(Config::Patch-foobarkey-prepend)
abc
def
ghi
EOT

my $data = Config::Patch->slurp($TESTFILE);
is($data, $shouldbe, "Patch prepended");

$patcher = Config::Patch->new(
              file => $TESTFILE,
              key  => "foobarkey");

$patcher->remove();

$data = Config::Patch->slurp($TESTFILE);
is($data, $TESTDATA, "Test file intact after removing patch");
