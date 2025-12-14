use v5.14;
use warnings;
use utf8;
use Encode;

use Test::More;
use Data::Dumper;
use File::Temp qw(tempdir);

use lib '.';
use t::Util;

$ENV{NO_COLOR} = 1;

# Use empty HOME to avoid reading user's .dozorc
my $empty_home = tempdir(CLEANUP => 1);
$ENV{HOME} = $empty_home;

# Test with null engine (no API key required)
subtest 'null engine' => sub {
    my $input = "Hello, World!\n";
    my $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'null engine exits successfully');
    like($result->stdout, qr/Hello, World!/, 'null engine returns input unchanged');
};

# Test output formats with null engine
subtest 'output formats' => sub {
    my $input = "Test line\n";

    # xtxt format (default)
    my $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA --xlate-format=xtxt .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'xtxt format works');
    like($result->stdout, qr/Test line/, 'xtxt output contains text');

    # cm format (conflict markers)
    $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA --xlate-format=cm .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'cm format works');
    like($result->stdout, qr/<<<<<<<.*=======.*>>>>>>>/s, 'cm output contains conflict markers');

    # ifdef format
    $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA --xlate-format=ifdef .+))
        ->setstdin($input)->run;
    is($result->status, 0, 'ifdef format works');
    like($result->stdout, qr/#ifdef/, 'ifdef output contains #ifdef');
};

# Test with file input
subtest 'file input' => sub {
    my $result = xlate(qw(--xlate --xlate-engine=null --xlate-to=JA .+), 'cpanfile')->run;
    is($result->status, 0, 'file input works');
    like($result->stdout, qr/requires/, 'file content is processed');
};

##############################################################################
# Tests for script/xlate command
##############################################################################

my $xlate_cmd = File::Spec->rel2abs('script/xlate');

sub run_xlate {
    my $out = `@_`;
    my $status = $? >> 8;
    return (Encode::decode('utf-8', $out), $status);
}

# Test script/xlate with null engine
subtest 'script/xlate with null engine' => sub {
    my ($out, $status) = run_xlate(qq{echo "Hello, World!" | $xlate_cmd -e null -t JA -p '.+' 2>&1});
    is($status, 0, 'script/xlate exits successfully');
    like($out, qr/Hello, World!/, 'output contains input text');
};

# Test script/xlate output formats
subtest 'script/xlate output formats' => sub {
    # cm format
    my ($out, $status) = run_xlate(qq{echo "Test" | $xlate_cmd -e null -t JA -o cm -p '.+' 2>&1});
    like($out, qr/<<<<<<<.*>>>>>>>/s, 'cm format produces conflict markers');

    # ifdef format
    ($out, $status) = run_xlate(qq{echo "Test" | $xlate_cmd -e null -t JA -o ifdef -p '.+' 2>&1});
    like($out, qr/#ifdef/, 'ifdef format produces #ifdef');
};

done_testing;
