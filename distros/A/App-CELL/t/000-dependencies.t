#!perl -T
use 5.012;
use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {

    # CORE modules
    use_ok( 'Carp' );
    use_ok( 'Data::Dumper' );
    use_ok( 'Exporter', qw( import ) );
    use_ok( 'File::Spec' );
    use_ok( 'File::Temp' );
    use_ok( 'Scalar::Util', qw( blessed ) );
    use_ok( 'Storable' );
    use_ok( 'Test::More' );

    # non-core (CPAN) modules
    use_ok( 'Date::Format' );
    use_ok( 'File::HomeDir' );
    use_ok( 'File::Next' );
    use_ok( 'File::ShareDir' );
    use_ok( 'Log::Any' );
    use_ok( 'Log::Any::Adapter' );
    use_ok( 'Log::Any::Test' );
    use_ok( 'Try::Tiny' );

    # modules in this distro
    use_ok( 'App::CELL', qw( $CELL $log $meta $core $site ) );
    use_ok( 'App::CELL::Config', qw( $meta $core $site ) );
    use_ok( 'App::CELL::Load' );
    use_ok( 'App::CELL::Log', qw( $log ) );
    use_ok( 'App::CELL::Message' );
    use_ok( 'App::CELL::Status' );
    use_ok( 'App::CELL::Util', qw( utc_timestamp is_directory_viable ) );
    use_ok( 'App::CELL::Test' );
    #use_ok( 'App::CELL::Test::LogToFile' );

}

#p( %INC );
#diag( "Testing Carp $Carp::VERSION, Perl $], $^X" );
#diag( "Testing Config::Simple $Config::Simple::VERSION, Perl $], $^X" );
#diag( "Testing CELL $App::CELL::VERSION, Perl $], $^X" );
#diag( "Testing App::CELL::Config $App::CELL::Config::VERSION, Perl $], $^X" );

done_testing;
