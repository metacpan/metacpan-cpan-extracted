use warnings;
use strict;
use Test::More;
use Test::Exception;
use HTTP::Request;

use App::SpamcupNG::UserAgent;

my $instance
    = new_ok( 'App::SpamcupNG::UserAgent' => ['0.1.0'], 'new instance' );
my @expected_attribs
    = qw(name version members_url code_login_url report_url current_base_url user_agent );

foreach my $expected (@expected_attribs) {
    ok( exists( $instance->{$expected} ),
        "the instance has an attribute $expected"
        );
}

is( $instance->base(), undef, 'base URL is undefined' );
isa_ok( $instance->{user_agent}, 'LWP::UserAgent', 'user_agent attribute' );
my @expected_methods = qw(login spam_report base complete_report user_agent _redact_auth_req);
can_ok( $instance, @expected_methods );
is( $instance->user_agent,
    'spamcup user agent/0.1.0',
    'user_agent returns the proper string'
    );
dies_ok { App::SpamcupNG::UserAgent->new } 'dies with missing parameter';
like ($@, qr/version\sis\srequired/, 'got the expected error message');

my $req = HTTP::Request->new( GET => 'http://members.spamcop.net/' );
$req->authorization_basic( 'foobar', '12345678910' );
my $expected = 'GET http://members.spamcop.net/' . "\n"
    . 'Authorization: Basic ************************';
is( $instance->_redact_auth_req($req),
    $expected, '_redact_auth_req works' );

done_testing;

# vim: filetype=perl
