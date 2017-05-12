#!perl
use warnings;
use strict;

BEGIN{ 
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/Dictionary-default.yml";
}

use Test::More;
use Test::Exception;
use Activator::Registry;
use Activator::Dictionary;
use Data::Dumper;
use IO::Capture::Stderr;

plan skip_all => 'test requires access to MySQL DB that can connect with \'mysql -u root\'. Set TEST_ACT_DB to enable this test' unless $ENV{TEST_ACT_DB};

my ($dict, $val, $capture, $line);

# test that when the db loads, duplicated column in a different table
# definition warns appropriately

system( "cat $ENV{PWD}/t/data/Dictionary-create-test.sql | mysql -u root");

# test loading from files. Gotta hack the registry to make this work for testing.
my $config = Activator::Registry->get( 'Activator::Dictionary' );
$config->{dict_files} = "$ENV{PWD}/t/data/Dictionary";

# get the english dictionary while testing for load warnings
my $expected_err1 = q([WARN] dictionary table t2 redefines value for realm 'realmdb2' key_prefix 'k2' column 'c2');
my $expected_err2 = q([WARN] dictionary table t2 redefines value for realm 'realmdb2' key_prefix 'k2' column 'c1');
$capture = IO::Capture::Stderr->new();
$capture->start();
lives_ok {
    $dict = Activator::Dictionary->get_dict();
} 'get_dict() does not die';
$capture->stop();
$line = $capture->read;
#ok ( $line =~ /$expected_err1/os, 'got first load error');
ok (defined $line, 'got first expected error');
$line = $capture->read;
#ok ( $line =~ /$expected_err2/os, 'got second load error');
ok (defined $line, 'got second expected error');
$val = $dict->lookup('fkey1');

ok( $val eq 'fvalue1', 'can lookup known key' );

lives_ok {
    $val = $dict->lookup('fkey2');
} "lookup doesn't die when looking up invalid key";
ok( !defined($val), 'unknown key returns undef by default' );

$val = $dict->lookup('fkey3');
ok( !defined($val), 'leading whitspace commented key returns undef');

$val = $dict->lookup('fkey4');
ok( $val eq 'fvalue4 has many words', 'multi-word values work');

$val = $dict->lookup('fkey5');
ok( $val eq 'fvalue5 has trailing whitespace', 'trailing whitespace stripped');

$val = $dict->lookup('fkey6');
ok( $val eq "  fvalue6 is quoted  ", 'quoted strings preserve whitespace');

$val = $dict->lookup('fkey7');
ok( $val eq 'fvalue 7 has nested "quotes"', 'nested quotes preserved');

# lookups from the db

$val = $dict->lookup('k1.c1', 'realmdb1');
ok( $val eq 'en_t1_c1', 'can fetch en db key' );

$capture = IO::Capture::Stderr->new();
$capture->start();
$dict->get_dict( 'de' );
$capture->stop();
$line = $capture->read;
ok( $line =~ /\[WARN\] Couldn't load dictionary from file for de/, 'missing dict file warns' );
ok( $dict->{cur_lang} eq 'de', 'switching languages works' );

$val = $dict->lookup('k1.c2', 'realmdb1');
ok( $val eq 'de_t2_c2', 'can fetch de db key' );

system( "cat $ENV{PWD}/t/data/Dictionary-drop-test.sql | mysql -u root");
