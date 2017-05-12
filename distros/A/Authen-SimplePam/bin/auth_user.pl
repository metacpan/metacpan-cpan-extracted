#!/usr/bin/perl

use Authen::SimplePam;
use Getopt::Std;

use strict;
use warnings;

our $opt_q;
getopts('q');

die "Usage: $0 [ -q ] <passoword> [ <user> ]\n"
  unless (defined ($ARGV[0]));

my ($password, $user, $res);
my $simple = new Authen::SimplePam;

$password = $ARGV[0];
$simple->password($password);


if (defined ($ARGV[1])) {
  $user = $ARGV[1];
  $simple->user($user);
}

$res = $simple->auth_user;

if ($res == 1) {
  print "Autentication successfull!\n" unless ($opt_q);
  exit 0;
} else {
  print "Authentication failure!\n" unless ($opt_q);
  exit 1;
}



