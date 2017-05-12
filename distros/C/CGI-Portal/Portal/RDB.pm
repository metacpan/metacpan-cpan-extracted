package CGI::Portal::RDB;
# Copyright (c) 2008 Alexander David P. All rights reserved.
#
# Database class

use strict;
use DBI;

use vars qw($VERSION);
$VERSION = "0.12";

1;

            # Connect to database and store handle in a rdb object
sub new {
  my ($class, $dsn, $user, $passw) = @_;
  my $i = {};

  $i->{'dbh'} = DBI->connect($dsn, $user, $passw);

  bless $i, $class;
  return $i;
}

            # Loop thru vals, escape them and join by commas
sub escape {
  my ($self, @vals) = @_;
  my @esc_vals;

  foreach my $a (@vals) {
    push(@esc_vals, $self->{'dbh'}->quote($a));
  }

  return join(',', @esc_vals);
}

            # Execute query and return statement handle
sub exec {
  my ($self, $sql) = @_;

  unless ($self->{'dbh'}){return;}

  my $sth = $self->{'dbh'}->prepare($sql);
  $sth->execute();

  return $sth;
}