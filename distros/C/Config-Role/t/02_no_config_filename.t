#!perl

use strict;
use warnings;
use rlib;
use Test::More tests => 6;
use File::Spec;

# Mock home/config dir location
{
    use File::HomeDir;
    no warnings 'redefine';
    sub File::HomeDir::my_data { return 't'; }
}

my $obj = My::Class->new();
isa_ok($obj, 'My::Class');
is( $obj->config_file, File::Spec->catfile('t', '.my_class.ini'), 'config_file attribute resolved correctly' );
is( ref($obj->config), ref({}), 'config attribute is a hashref' );
ok( exists $obj->config->{'username'}, 'config key username exists' );
is( $obj->config->{'username'}, 'robin', 'config key username matches' );
is( $obj->username, 'robin', 'required attribute username found in config' );

BEGIN {
    package My::Class;
    use Moose;
    with 'Config::Role';

    # Fetch a value from the configuration, allow constructor override
    has 'username' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_username { return (shift)->config->{'username'}; }
}
