#!/usr/bin/perl

use Authen::SimplePam qw(change_password);
use Getopt::Std;

use strict;
use warnings;

our $opt_q;
getopts('q');

if ($#ARGV < 1 ) {
	die "Usage: $0 [ -q ] <old_password> <new_password>  [ <username> ]\n";
}

my $old_password = $ARGV[0];
my $new_password = $ARGV[1];

my $simple = new Authen::SimplePam;
$simple->old_password($old_password);
$simple->new_password($new_password);

if (defined($ARGV[2])) {
  my $user = $ARGV[2];
  $simple->user($user);
}

print "Changing password for " . $simple->user . "\n" unless ($opt_q);

my $result = $simple->change_password();

if ($result == 1)
{
  print "Password for user " . $simple->user . " successfully changed!\n" unless ($opt_q);
  exit 0;
}
else
{
  print "Error changing password for user " . $simple->user . "!\n" unless ($opt_q);
  exit 1;
}
