#!/usr/bin/env perl
# Example script to check authentication on a RADIUS server
use strict;
use warnings;
use Authen::Radius;

my $verbose = 0;
$verbose = 1 if (($ARGV[0] // '') eq '--verbose');

STDOUT->autoflush(1);

print "Make sure this machine is in your Radius clients file!\n";

print "Enter hostname[:port] of your Radius server: ";
chomp( my $host = <STDIN> );

print "Enter shared-secret of your Radius server: ";
chomp( my $secret = <STDIN> );

print "Enter a username to be validated: ";
chomp( my $user = <STDIN> );

print "Enter this user's password: ";
chomp( my $pwd = <STDIN> );

my $r = Authen::Radius->new(
            Host   => $host,
            Secret => $secret,
            Debug  => $verbose,
        );

Authen::Radius->load_dictionary();

my $result = $r->check_pwd( $user, $pwd );
if ($result) {
    print "Accept\n";
}
elsif ($r->get_error() eq 'ENONE') {
    print "Reject\n";
}
else {
    print 'Error: ', $r->strerror(), "\n";
    exit 1;
}

my @attributes = $r->get_attributes();
foreach my $attr (@attributes) {
    printf "%s %s = %s\n", $attr->{Vendor} // ' ', $attr->{Name}, $attr->{Value} // $attr->{RawValue};
}
