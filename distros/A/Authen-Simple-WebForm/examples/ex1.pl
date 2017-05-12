#!/usr/bin/perl

# Demo to auth against freshmeat.net

use strict;
use Authen::Simple::WebForm;
use Authen::Simple::Log;
use Term::ReadKey();

my $log = Authen::Simple::Log->new();

my $webform = Authen::Simple::WebForm->new(
    'log'               => $log,
    initial_url         => 'http://freshmeat.net/session/new?return_to=/',
    login_url           => 'http://freshmeat.net/session',
    login_expect        => 'href="/logout"',
    login_expect_cookie => 'user_credentials',
    username_field      => 'user_session[login]',
    password_field      => 'user_session[password]',
    extra_fields        => [
        'commit' => 'Log in!',
        'user_session[remember_me]' => 0,
        'user_session[openid_identifier]'   => '',
        ],
);

print "USER: ";
my $username = <STDIN>;
chomp($username);

print "PASS: ";
my $password;
{
    local $SIG{INT} = sub { Term::ReadKey::ReadMode('restore'); print "\n"; exit 1; };
    Term::ReadKey::ReadMode('noecho');
    $password = Term::ReadKey::ReadLine(0);
    Term::ReadKey::ReadMode('restore');
    chomp($password);
}


if ($webform->authenticate($username, $password)) {
    print "OK\n";
} else {
    print "NOK\n";
    exit 1;
}

