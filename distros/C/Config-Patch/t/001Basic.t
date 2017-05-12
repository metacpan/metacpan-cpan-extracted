######################################################################
# Test suite for Config::Patch
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More tests => 24;
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
# Single patch 
####################################################
Config::Patch->blurt($TESTDATA, $TESTFILE);

my $patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "foobarkey");

$patcher->append(<<'EOT');
This is
a patch.
EOT

    # Check if patch got applied correctly
my($patches, $hashref) = $patcher->patches();
ok(exists $hashref->{"foobarkey"}, "Patch exists");
is($patches->[0]->[0], "foobarkey", "Patch in patch list");
is($patches->[0]->[1], "append", "Patch mode correct");
is($patches->[0]->[2], "This is\na patch.\n", "Patch text correct");

my $shouldbe = <<'EOT';
abc
def
ghi
#(Config::Patch-foobarkey-append)
This is
a patch.
#(Config::Patch-foobarkey-append)
EOT

my $data = Config::Patch->slurp($TESTFILE);
is($data, $shouldbe, "Patch appended");

    # Remove patch
$patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "foobarkey");

$patcher->remove();

$data = Config::Patch->slurp($TESTFILE);
is($data, $TESTDATA, "Test file intact after removing patch");

####################################################
# Double patch
####################################################
Config::Patch->blurt($TESTDATA, $TESTFILE);

$patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "foobarkey");

$patcher->append(<<'EOT');
This is
a patch.
EOT

open FILE, ">>$TESTFILE" or die;
print FILE $TESTDATA;
close FILE;

$patcher->read();
$patcher->key("anotherkey");
$patcher->append(<<'EOT');
This is
another patch.
EOT

    # Check if patch got applied correctly
($patches, $hashref) = $patcher->patches();
ok(exists $hashref->{"foobarkey"}, "Patch exists");

is($patches->[0]->[0], "foobarkey", "Patch in patch list");
is($patches->[1]->[0], "anotherkey", "Patch in patch list");

is($patches->[0]->[1], "append", "Patch mode correct");
is($patches->[1]->[1], "append", "Patch mode correct");

is($patches->[0]->[2], "This is\na patch.\n", "1st patch text correct");
is($patches->[1]->[2], "This is\nanother patch.\n", "2nd patch text correct");

    # Remove patch
$patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "foobarkey");

$patcher->key("anotherkey");
$patcher->remove();

$patcher->key("foobarkey");
$patcher->remove();

$data = Config::Patch->slurp($TESTFILE);
is($data, $TESTDATA . $TESTDATA, 
    "Test file intact after removing both patches");

######################################################################3
# Try a patch with a key containing a '-'

Config::Patch->blurt($TESTDATA, $TESTFILE);

$patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "foo-bar-key");

$patcher->append(<<'EOT');
This is
a patch.
EOT

    # Check if patch got applied correctly
($patches, $hashref) = $patcher->patches();
ok(exists $hashref->{"foo-bar-key"}, "Patch exists");

is($patches->[0]->[0], "foo-bar-key", "Patch in patch list");

is($patches->[0]->[1], "append", "Patch mode correct");

is($patches->[0]->[2], "This is\na patch.\n", "1st patch text correct");

$patcher->remove();

$data = Config::Patch->slurp($TESTFILE);
is($data, $TESTDATA, 
    "Test file intact after removing both patches");

######################################################################3
# Try a patch with comment character ';'

Config::Patch->blurt($TESTDATA, $TESTFILE);

$patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "mykey",
                  comment_char => ';',
);

$patcher->append(<<'EOT');
This is
a patch.
EOT

$data = Config::Patch->slurp($TESTFILE);
like($data, qr(^;)m, "Comment char is ;");

$patcher->remove();
$data = Config::Patch->slurp($TESTFILE);
is($data, $TESTDATA, 
    "Test file intact after removing comment char ; patch");

######################################################################3
# Try a patch with comment character ';'

Config::Patch->blurt($TESTDATA, $TESTFILE);

$patcher = Config::Patch->new(
                  file => $TESTFILE,
                  key  => "mykey",
                  comment_char => ';',
);

$patcher->replace(qr(^def$)m,
                  "oh!\nmy!\n");

$patcher->save();
$data = Config::Patch->slurp($TESTFILE);
like($data, qr(^;)m, "Comment char is ;");

$patcher->remove();
$data = Config::Patch->slurp($TESTFILE);
is($data, $TESTDATA, 
    "Test file intact after removing comment char ; patch");
