# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-U2F.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 9;
BEGIN { 
    use_ok('Crypt::U2F::Server::Simple');
    use_ok('JSON::XS');
};

use Data::Dumper;

#########################

my $crypter = Crypt::U2F::Server::Simple->new(appId=>'Perl', origin=>'http://search.cpan.org');
ok(defined($crypter), 'new()');

if(!defined($crypter)) {
    diag(Crypt::U2F::Server::Simple::lastError());
}

my $challenge = $crypter->registrationChallenge();

my $parsed = JSON::XS->new->utf8->decode($challenge);
ok(defined($parsed), 'Parsing JSON string');
#diag(Dumper(\$parsed));

foreach my $key (qw[challenge version appId]) {
    ok(defined($parsed->{$key}), "Defined: $key");
}

ok($parsed->{version} eq 'U2F_V2', 'supported library version');
ok($parsed->{appId} eq 'Perl', 'appID roundtrip');
