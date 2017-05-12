package testlib;

use lib qw(t/testapp/lib);
use warnings;
use strict;

use Test::Most;
use JSON;
use Test::WWW::Mechanize::Catalyst;


sub import {
    my ($class) = @_;
    my $caller = scalar caller();

    strict->import;
    warnings->import;
    
    no strict 'refs';
    *{$caller.'::init'}=\&init;
    *{$caller.'::request'}=\&request;

}

sub init {
    return Test::WWW::Mechanize::Catalyst->new(
        catalyst_app => 'TestApp',
        cookie_jar => {},
    );
}

sub request {
    my ($mech) = shift;
    
    $mech->get_ok(@_);
    
    my $response = eval {
        return decode_json($mech->content);
    };
    if (! $response || $@) {
        fail('Could not parse JSON: '.$mech->content);
    } else {
        pass('JSON ok');
    }
    return $response;
}

1;