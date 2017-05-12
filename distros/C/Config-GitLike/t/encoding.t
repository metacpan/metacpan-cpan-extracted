use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw/tempdir/;
use lib 't/lib';
use TestConfig;

my $config_dirname = tempdir( CLEANUP => !$ENV{CONFIG_GITLIKE_DEBUG} );
my $config_filename = File::Spec->catfile( $config_dirname, 'config' );

diag "config file is: $config_filename" if $ENV{TEST_VERBOSE};

my $config = TestConfig->new(
    confname => 'config',
    tmpdir => $config_dirname,
    encoding => 'UTF-8',
);
$config->load;

UTF8: {
    use utf8;
    $config->set(
        key      => 'core.penguin',
        value    => 'little blüe',
        filename => $config_filename
    );
}

my $expect = qq{[core]\n\tpenguin = little blüe\n};
is( $config->slurp, $expect, 'Value with UTF-8' );

$config->load;
UTF8: {
    use utf8;
    is $config->get(key => 'core.penguin'), 'little blüe',
        'Get value with UTF-8';
}


done_testing;
