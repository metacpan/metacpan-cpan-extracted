package testlib;

use strict;
use warnings;
use 5.010;
no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Business::UPS::Tracking;

sub import {
    my $class  = shift;
    my $caller = caller;

    strict->import;
    warnings->import;
    feature->import(':5.10.0');

    no strict 'refs';
    *{ $caller . '::tracking' }    = \&tracking;
    *{ $caller . '::testrequest' } = \&testrequest;
    *{ $caller . '::testcheck' } = \&testcheck;
}

sub tracking {
    return Business::UPS::Tracking->new(
        UserId              => 'we@revdev.at',
        Password            => 'secret',
        AccessLicenseNumber => '8C44FC5D5E88C868',
    );
}

sub testcheck {
    my ($skiptests) = @_;
    
    my $tracking = tracking();
    my $url = $tracking->url();
    $url =~ s/^(https?:\/\/.+\/).+$/$1/;
    my $response = $tracking->_ua()->get($url);
    
    return $response->is_success || $response->code == 404;
}

sub testrequest {
    my (%params) = @_;

    $params{tracking} ||= tracking();

    my $response = eval {
        my $request = Business::UPS::Tracking::Request->new( %params, );
        return $request->run;
    };
    if ( my $e = Exception::Class->caught ) {
        given ($e) {
            when ( !ref $_ ) {
                die 'UNKNOWN ERROR:' . $e;
            }
            when ( $_->isa('Business::UPS::Tracking::X::HTTP') ) {
                die 'HTTP ERROR:' . $e->full_message;
            }
            when ( $_->isa('Business::UPS::Tracking::X::UPS') ) {
                die 'DPD ERROR:' . $e->full_message . ' (' . $e->code . ')';
            }
            when ( $_->isa('Business::UPS::Tracking::X::XML') ) {
                die 'XML ERROR:' . $e->full_message;
            }
            default {
                die 'OTHER ERROR:' . $e;
            }
        }
    }

    return $response;
}

1;
