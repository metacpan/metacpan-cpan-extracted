use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Config::JFDI;
use t::Test;

sub has_Config_General {
    return eval "require Config::General;";
}

{
    my $config = Config::JFDI->open( 't/assets/some_random_file.pl' );
    ok( $config );
    ok( keys %{ $config } );
}

{
    my $config = Config::JFDI->open( qw{ name xyzzy path t/assets } );
    ok( $config );
    ok( keys %{ $config } );
}

{
    my $config = Config::JFDI->open( 't/assets/missing-file.pl' );
    ok( ! $config );
}

{
    my $config = Config::JFDI->new(
        file => 't/assets/some_random_file.pl'
    );
    warning_like { $config->open( '...' ) } qr/You called ->open on an instantiated object with arguments/;
}

{
    my ($config_hash, $config) = Config::JFDI->open( qw{ name xyzzy path t/assets } );
    ok( $config_hash );
    is( ref $config_hash, 'HASH' );
    isa( $config, 'Config::JFDI' );
}

