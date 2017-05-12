#perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::Differences;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec;
use File::Slurp qw(slurp);
use Try::Tiny;
use App::Pmhack qw(pmhack);

# setup
my $lib = File::Spec->catdir($FindBin::Bin, 'lib');
my $original_filename = File::Spec->catfile($lib, qw( App Pmhack Test.pm ));
my $original_file = slurp($original_filename);
my $module_name = "App::Pmhack::Test";
my $tempdir = tempdir();
my $targeted_filename = File::Spec->catfile($tempdir, qw( App Pmhack Test.pm ));
local $ENV{PERL5HACKLIB} = $tempdir;
unshift @INC, $lib;
my $new_filename = pmhack($module_name);
my $new_file = try { slurp($new_filename) };

# run tests
is($new_filename, $targeted_filename, "target filename as expected");
ok( -e $new_filename && -f $new_filename, "target file exists");
eq_or_diff($new_file, $original_file, "target matches source");

#exit
try { unlink $tempdir }
catch { "Could not unlink temporary directory $tempdir" };
