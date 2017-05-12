#!perl -w
use strict;
use warnings;
use DBI;
use Carp;

$SIG{__WARN__} = sub { confess $_[0] };

my $dbh = DBI->connect;

cleanup();

sub cleanup {
  $dbh->disconnect;
  $dbh = DBI->connect;
}
