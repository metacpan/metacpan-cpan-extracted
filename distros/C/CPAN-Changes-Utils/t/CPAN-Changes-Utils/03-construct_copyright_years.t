use strict;
use warnings;

use CPAN::Changes;
use CPAN::Changes::Utils qw(construct_copyright_years);
use File::Object;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Data dir.
my $data_dir = File::Object->new->up->dir('data');

# Test.
my $changes = CPAN::Changes->load($data_dir->file('ex1.changes')->s);
my $ret = construct_copyright_years($changes);
is($ret, undef, 'Get copyright years (undef - only preable).');

# Test.
$changes = CPAN::Changes->load($data_dir->file('ex2.changes')->s);
$ret = construct_copyright_years($changes);
is($ret, undef, 'Get copyright years (undef - blank file).');

# Test.
$changes = CPAN::Changes->load($data_dir->file('ex3.changes')->s);
$ret = construct_copyright_years($changes);
is($ret, '2009', 'Get copyright years (2009 - only one year).');

# Test.
$changes = CPAN::Changes->load($data_dir->file('ex4.changes')->s);
$ret = construct_copyright_years($changes);
is($ret, undef, 'Get copyright years (undef - release item without year).');

# Test.
$changes = CPAN::Changes->load($data_dir->file('ex5.changes')->s);
$ret = construct_copyright_years($changes);
is($ret, '2009-2019', 'Get copyright years (2009-2019 - two years).');

# Test.
$changes = CPAN::Changes->load($data_dir->file('ex6.changes')->s);
$ret = construct_copyright_years($changes);
is($ret, '2009-2019', 'Get copyright years (2009-2019 - two years, with release without date).');
