#!perl -T

use strict;
use warnings;
use Test::More tests => 13;
use Blitz;
use Scalar::Util qw(blessed);

my $obj = Blitz->new();

create_object_ok();
test_defaults();
test_setters_and_getters();
new_blitz();
new_rush();

sub create_object_ok {
    is( blessed($obj), 'Blitz', 'Creating a new object OK');
}

sub test_defaults {
    is( $obj->username, undef, "If not given, username initially unset");
    is( $obj->api_key, undef, "If not given, api_key initially unset");
    is( $obj->host, 'blitz.io', 'Default host correct');
    is( $obj->port, 80, 'Default port correct');
}

sub test_setters_and_getters {
    my $set = {
        port => 8080,
        host => 'google.com',
        api_key => '12345678-12345678-12345678-12345678',
        username => 'foo@foo.com',
    };
    for my $key (keys %$set) {
        $obj->$key($set->{$key});
    }
    
    is( $obj->port, $set->{port}, 'Setting and getting port works');
    is( $obj->username, $set->{username}, 'Setting and getting username works');
    is( $obj->host, $set->{host}, 'Setting and getting host works');
    is( $obj->api_key, $set->{api_key}, 'Setting and getting api_key works');

}

sub new_blitz {
    my $sprint = Blitz::Sprint->new( $obj, { options => { pattern => 'foo'}});

    is( $sprint->{test_type}, 'sprint', "Sprint object correctly identified as Sprint");
    ok( ! $sprint->{options}{pattern}, "Pattern is stripped from options sent to Sprint");
}

sub new_rush {
    my $rush = Blitz::Rush->new( $obj, { pattern => 'foo'});
    is ( $rush->{test_type}, 'rush', "Rush object correctly identified as Rush");
    ok( $rush->{options}{pattern}, "Pattern is not stripped from options sent to Rush");
}
