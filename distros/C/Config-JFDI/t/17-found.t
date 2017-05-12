use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Config::JFDI;

sub has_Config_General {
    return eval "require Config::General;";
}

{
    my $config = Config::JFDI->new( file => 't/assets/some_random_file.pl', quiet_deprecation => 1 );

    ok( $config->get );
    ok( keys %{ $config->get } );
    ok( $config->found );
    cmp_deeply( [ $config->found ], bag( 't/assets/some_random_file.pl' ) );
}

{
    my $config = Config::JFDI->new( qw{ name xyzzy path t/assets } );
    ok( $config->get );
    ok( keys %{ $config->get } );
    ok( $config->found );
    cmp_deeply( [ $config->found ], bag( 't/assets/xyzzy.pl', 't/assets/xyzzy_local.pl' ) );
}

{
    my $config = Config::JFDI->new( file => 't/assets/missing-file.pl', quiet_deprecation => 1 );

    ok( $config->get );
    cmp_deeply( $config->get, {} );
    ok( !$config->found );
}

{
    my $config = Config::JFDI->new( file => 't/assets/some_random_file.pl', quiet_deprecation => 1 );

    ok( $config->found ); # Do ->read via ->found
    ok( $config->get );
    ok( keys %{ $config->get } );
    cmp_deeply( [ $config->found ], bag( 't/assets/some_random_file.pl' ) );
}

