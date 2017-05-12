#!perl

use Test::NoWarnings;
use Test::More tests => 4 + 1;

use lib qw(t/);
use testlib;


$Business::UPS::Tracking::CHECKSUM = 0;

SKIP:{
    skip "Could not connect to UPS online tracking webservices", 4 
        unless testcheck();
    
    eval {
        my $request = Business::UPS::Tracking::Request->new( 
            TrackingNumber    => '1Z12345E0291980790',
            tracking          => &tracking,
        );    
        return $request->run; 
    };
    
    if (my $e = Business::UPS::Tracking::X::UPS->caught) {
        pass('We have a Business::UPS::Tracking::X::UPS exeption');
        is($e->code,'151018','Exception code is ok');
    } else {
        fail('Did not get a Business::UPS::Tracking::X::UPS exception');
        fail('Cannot check exception');
    }

    eval {
        my $tracking = &tracking;
        $tracking->url('https://really-broken-url-and-simulate-http-exception.com');
        my $request = Business::UPS::Tracking::Request->new( 
            TrackingNumber    => '1Z12345E0291980790',
            tracking          => $tracking,
        );    
        return $request->run; 
    };
    
    if (my $e = Business::UPS::Tracking::X::HTTP->caught) {
        pass('We have a Business::UPS::Tracking::X::HTTP exeption');
        like($e->http_response->as_string ,qr/^50[03]\s/,'HTTP response is ok');
    } else {
        fail('Did not get a Business::UPS::Tracking::X::HTTP exception');
        fail('Cannot check exception');
    }

}
$Business::UPS::Tracking::CHECKSUM = 1;

#{
#    eval {
#        my $tracking = &tracking;
#        my $request = Business::UPS::Tracking::Request->new( 
#            TrackingNumber    => '1Z12345E0291980790',
#            tracking          => $tracking,
#        );    
#        return $request->run; 
#    }; 
#    
#    if (my $e = Business::UPS::Tracking::X::CLASS->caught) {
#        pass('We have a Business::UPS::Tracking::X::CLASS exeption');
#        like($e->error,qr/Attribute \(TrackingNumber\) does not pass the type constraint because: Tracking numbers/,'Errormessage is ok');
#    } else {
#        fail('Did not get a Business::UPS::Tracking::X::CLASS exception');
#        fail('Cannot check exception');
#    }
#}