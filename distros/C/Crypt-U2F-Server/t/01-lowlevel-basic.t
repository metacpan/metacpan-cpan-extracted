# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-U2F.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 15;
BEGIN { 
    use_ok('Crypt::U2F::Server');
    use_ok('JSON::XS');
};

use Data::Dumper;

#########################

my $rc = Crypt::U2F::Server::u2fclib_init(0);
is($rc, 1, 'u2fclib_init');
if(!$rc) {
    diag('error scalar: ' . Crypt::U2F::Server::u2fclib_getError());
}

my $ctx = Crypt::U2F::Server::u2fclib_get_context();
ok(defined($ctx), 'u2fclib_init ctx defined');
ok($ctx > 0, 'u2fclib_init ctx != 0');
#diag("ctx pointer': $ctx");

$rc = Crypt::U2F::Server::u2fclib_setAppID($ctx, 'Perl');
is($rc, 1, 'u2fclib_setAppID');
if(!$rc) {
    diag('error scalar: ' . Crypt::U2F::Server::u2fclib_getError());
}

$rc = Crypt::U2F::Server::u2fclib_setOrigin($ctx, 'http://search.cpan.org');
is($rc, 1, 'u2fclib_setOrigin');
if(!$rc) {
    diag('error scalar: ' . Crypt::U2F::Server::u2fclib_getError());
}

my $challenge = Crypt::U2F::Server::u2fclib_calcRegistrationChallenge($ctx);
ok(length($challenge) > 0, 'u2fclib_calcRegistrationChallenge');
if(!length($challenge)) {
    diag('error scalar: ' . Crypt::U2F::Server::u2fclib_getError());
}

my $parsed = JSON::XS->new->utf8->decode($challenge);
ok(defined($parsed), 'Parsing JSON string');
#diag(Dumper(\$parsed));

foreach my $key (qw[challenge version appId]) {
    ok(defined($parsed->{$key}), "Defined: $key");
}

ok($parsed->{version} eq 'U2F_V2', 'supported library version');
ok($parsed->{appId} eq 'Perl', 'appID roundtrip');

is(Crypt::U2F::Server::u2fclib_deInit(), 1, 'u2fclib_deInit');
