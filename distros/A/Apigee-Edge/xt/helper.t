#!/usr/bin/perl

use strict;
# use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Apigee::Edge::Helper;
use Data::Dumper;
use Test::More;

plan skip_all => "ENV APIGEE_ORG/APIGEE_USR/APIGEE_PWD is required to continue."
    unless $ENV{APIGEE_ORG} and $ENV{APIGEE_USR} and $ENV{APIGEE_PWD};
my $apigee = Apigee::Edge::Helper->new(
    org => $ENV{APIGEE_ORG},
    usr => $ENV{APIGEE_USR},
    pwd => $ENV{APIGEE_PWD}
);

my $email = 'fayland@binary.com';

## cleanup
$apigee->delete_developer($email);;

say "Register Apps...";
my $app = $apigee->refresh_developer_app(
    email       => $email,
    name        => 'Fayland Test App',
    callbackUrl => 'http://fayland.me/oauth/callback',
    # apiProducts => ['ProductName'],
    firstName   => 'Fayland',
    lastName    => 'Lam',
    userName    => 'fayland.binary',
);
# say Dumper(\$app);

ok($app->{appId});
is($app->{callbackUrl}, 'http://fayland.me/oauth/callback');
is($app->{name}, 'Fayland Test App');
is($app->{display_name}, 'Fayland Test App');
ok($app->{credentials});
ok($apigee->errstr =~ /registered/);

say "Get Clients...";
my $clients = $apigee->get_all_clients();
ok(grep { $_ eq $app->{credentials}->[0]->{consumerKey} } keys %$clients);
ok(grep { $_ eq 'Fayland Test App' } values %$clients);

say "Update Apps...";
$app = $apigee->refresh_developer_app(
    app         => $app,
    email       => $email,
    name        => 'Fayland Test App Changed',
    callbackUrl => 'http://fayland.me/oauth/callback_changed',
    # apiProducts => ['ProductName'],
    firstName   => 'Fayland',
    lastName    => 'Lam',
    userName    => 'fayland.binary',
);
# say Dumper(\$app);

ok($app->{appId});
is($app->{callbackUrl}, 'http://fayland.me/oauth/callback_changed');
is($app->{name}, 'Fayland Test App'); # this is not changed
is($app->{display_name}, 'Fayland Test App Changed');
ok($app->{credentials});
ok($apigee->errstr =~ /Update successful/);

say "Get Clients...";
my $clients = $apigee->get_all_clients();
ok(grep { $_ eq $app->{credentials}->[0]->{consumerKey} } keys %$clients);
ok(grep { $_ eq 'Fayland Test App Changed' } values %$clients);

done_testing();

1;