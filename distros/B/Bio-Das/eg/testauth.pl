#!/usr/bin/perl

# $Id: testauth.pl,v 1.1 2004/01/03 00:23:40 lstein Exp $
# this script illustrates how to use an authentication callback

use lib '.';
use strict;
use Bio::Das;

my $db = Bio::Das->new(-auth_callback=>\&authorize);
$db->no_rfc_warning(1);

$db->debug(0);
my @result = $db->entry_points(-dsn=>['http://dev.wormbase.org/db/das/protected',
				      'http://dev.wormbase.org/db/das/elegans',
				     ]);
foreach (@result) {
  if ($_->is_success) {
    my @entry_points = $_->results;
    print $_->dsn,"\n";
    print "\t",join ' ',@entry_points,"\n";
  } else {
    print $_->error,"\n";
  }
}

sub authorize {
  my ($fetcher,$domain,$iteration_count) = @_;
  return if $iteration_count > 3;
  my $host = $fetcher->request->host;
  print STDERR "$host/$domain requires authentication (try $iteration_count of 3)\n";
  print STDERR "username = testuser, password = testpass\n";
  print STDERR "Username: ";
  chomp (my $username = <>);
  print STDERR "Password: ";
  chomp (my $password = <>);
  return ($username,$password);
}
