#!perl
use warnings;
use strict;

BEGIN{ 
    $ENV{ACT_REG_YAML_FILE} ||= "$ENV{PWD}/t/data/Dictionary-dies.yml";
}

use Test::More;
use Test::Exception;
use Activator::Registry;
use Activator::Dictionary;
use Data::Dumper;

plan skip_all => 'test requires access to MySQL DB that can connect with \'mysql -u root\'. Set TEST_ACT_DB to enable this test' unless $ENV{TEST_ACT_DB};

my ($dict, $val);

# test loading from files. Gotta hack the registry to make this work for testing.
my $config = Activator::Registry->get( 'Activator::Dictionary' );
$config->{dict_files} = "$ENV{PWD}/t/data/Dictionary";

# get the english dictionary
lives_ok {
    $dict = Activator::Dictionary->get_dict();
} 'get_dict() does not die';

$val = $dict->lookup('fkey1');
ok( $val eq 'fvalue1', 'can lookup known key' );

dies_ok {
    $val = $dict->lookup('fkey2');
} "lookup dies when looking up invalid key";

lives_ok { 
    $val = $dict->lookup('fkey3');
} "lookup doesn't die when realm defined in fail_mode";
ok( $val eq 'backup value', "lookup returns defined realm's value in fail_mode" );

