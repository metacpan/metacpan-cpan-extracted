use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Data directory.
my $data_dir = File::Object->new->up->dir('data')->set;

# Test.
my $ret = detect_dwg_file($data_dir->file('ex1.dwg')->s);
is($ret, 'MC0.0', 'MC0.0 DWG file.');

# Test.
$ret = detect_dwg_file($data_dir->file('ex2.dwg')->s);
is($ret, 'AC1.2', 'AC1.2 DWG file.');

# Test.
$ret = detect_dwg_file($data_dir->file('ex3.dwg')->s);
is($ret, 'AC1003', 'AC1003 DWG file.');

$ret = detect_dwg_file($data_dir->file('fake.dwg')->s);
is($ret, undef, 'Fake DWG file.');

# Test.
eval {
	detect_dwg_file('Foo');
};
is($EVAL_ERROR, "Cannot open file 'Foo'.\n", "Cannot open file 'Foo'.");
clean();
