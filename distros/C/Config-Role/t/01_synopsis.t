#!perl

use strict;
use warnings;
use rlib;
use Test::More tests => 9;
use File::Spec;

# Mock home/config dir location
{
    use File::HomeDir;
    no warnings 'redefine';
    sub File::HomeDir::my_data { return 't'; }
}

my $obj = My::Class->new();
isa_ok($obj, 'My::Class');
can_ok($obj, qw(
    config_dir
    config_file
    config
));
is( $obj->config_dir, 't', 'config_dir attribute resolved correctly' );
is( $obj->config_file, File::Spec->catfile('t', '.my_class.ini'), 'config_file attribute resolved correctly' );
is( ref($obj->config), ref({}), 'config attribute is a hashref' );
is( $obj->username, 'robin', 'required attribute username found in config' );

my $obj2 = My::Class->new( config_file => File::Spec->catfile('t', '.missing.ini') );
is_deeply( $obj2->config, {}, 'missing config file should give empty config' );

my $obj3 = My::Class->new(
    config_files => [
        File::Spec->catfile('t', '.my_class.ini'),
        File::Spec->catfile('t', '.my_other_class.ini'),
    ],
);
is( scalar @{ $obj3->config_files }, 2, "two config files specified" );
is( $obj3->username, 'robin', 'username attribute should come from first file' );

BEGIN {
    package My::Class;
    use Moose;

    # Read configuration from ~/.my_class.ini, available in $self->config
    has 'config_filename' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_config_filename { '.my_class.ini' }
    with 'Config::Role';

    # Fetch a value from the configuration, allow constructor override
    has 'username' => ( is => 'ro', isa => 'Str', lazy_build => 1 );
    sub _build_username { return (shift)->config->{'username'}; }
}
