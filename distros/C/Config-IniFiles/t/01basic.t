#!/usr/bin/perl
use strict;
use warnings;

# Should be 10.
use Test::More tests => 10;

use Config::IniFiles;

use lib "./t/lib";

use Config::IniFiles::Debug;
use Config::IniFiles::TestPaths;

my ($value, @value);
umask 0000;

my $ini = Config::IniFiles->new(-file => t_file("test.ini"));
$ini->_assert_invariants();
t_unlink("test01.ini");
$ini->SetFileName(t_file("test01.ini"));
$ini->SetWriteMode("0666");

# TEST
ok($ini, "Loading from a file");

$value = $ini->val('test1', 'one');
$ini->_assert_invariants();
# TEST
is (
    $value, 'value1',
    "Reading a single value in scalar context"
);

@value = $ini->val('test1', 'one');
$ini->_assert_invariants();
# TEST
is ($value[0], 'value1', "Reading a single value in list context");

$value = $ini->val('test1', 'mult');
# TEST
is ($value, "one$/two$/three",
    "Reading a multiple value in scalar context"
);

@value = $ini->val('test1', 'mult');
$value = join "|", @value;
# TEST
is_deeply(
    \@value,
    ["one", "two", "three"],
    "Reading a multiple value in list context",
);

@value = ("one", "two", "three");
$ini->newval('test1', 'eight', @value);
$ini->_assert_invariants();
$value = $ini->val('test1', 'eight');
# TEST
is (
    $value,
    "one$/two$/three",
    "Creating a new multiple value",
);

$ini->newval('test1', 'seven', 'value7');
$ini->_assert_invariants();
$ini->RewriteConfig;
$ini->ReadConfig;
$ini->_assert_invariants();
$value='';
$value = $ini->val('test1', 'seven');
$ini->_assert_invariants();
# TEST
is ($value, 'value7', "Creating a new value",);

$ini->delval('test1', 'seven');
$ini->_assert_invariants();
$ini->RewriteConfig;
$ini->ReadConfig;
$ini->_assert_invariants();
$value='';
$value = $ini->val('test1', 'seven');
# TEST
ok (! defined ($value), "Deleting a value");

$value = $ini->val('test1', 'not a real parameter name', '12345');
# TEST
is ($value, '12345', "Reading a default values from existing section");

$value = $ini->val('not a real section', 'no parameter by this name', '12345');
# TEST
is ($value, '12345', "Reading a default values from non-existent section");

# Clean up when we're done
t_unlink("test01.ini");

