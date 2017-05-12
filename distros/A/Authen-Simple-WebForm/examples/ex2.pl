#!/usr/bin/perl

use strict;
use Authen::Simple::WebForm;
use Authen::Simple::Log;
use Term::ReadKey();

my $log = Authen::Simple::Log->new();

my $webform = Authen::Simple::WebForm->new(
    'log'               => $log,
    initial_url         => 'http://host.company.com',
    check_initial_status_code => 0,
    login_url           => 'http://host.company.com/auth/LOGIN',
#   login_expect        => 'Employee Identification Number',
#   login_expect        => qr/Employee Identification Number/,
    login_expect_cookie => 'COMPANYSession',
    username_field      => 'credential_0',
    password_field      => 'credential_1',
    extra_fields        => [ 'destination' => '/cgi-bin/siteIndex.pl' ],
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

