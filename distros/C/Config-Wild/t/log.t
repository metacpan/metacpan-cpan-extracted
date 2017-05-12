#!perl


use Test::More;
use Test::Fatal;

use Log::Any::Test;
use Log::Any '$log';


use Config::Wild;

subtest 'non existent file' => sub {

    my $exception
      = exception { Config::Wild->new( "this really doesn't exist" ) };

    ok( ref $exception && $exception->isa( 'Config::Wild::Error::exists' ),
        "throw Config::Wild::Error::exists error" );

    $log->contains_ok( qr/unable to find/, "log file failure" );

};

done_testing;
