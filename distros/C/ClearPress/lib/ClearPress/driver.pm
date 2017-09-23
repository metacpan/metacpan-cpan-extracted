# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
# Created: 2006-10-31
#
package ClearPress::driver;
use strict;
use warnings;
use Carp;
use ClearPress::driver::mysql;
use ClearPress::driver::SQLite;
use DBI;
use English qw(-no_match_vars);
use Carp;

our $VERSION = q[476.4.2];

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};
  bless $ref, $class;
  return $ref;
}

sub dbh {
  my $self = shift;
  carp q[dbh unimplemented];
  return;
}

sub new_driver {
  my ($self, $drivername, $ref) = @_;

  my $drvpkg = "ClearPress::driver::$drivername";
  return $drvpkg->new({
		       drivername => $drivername,
		       %{$ref},
		      });
}

sub DESTROY {
  my $self = shift;

  if($self->{dbh} && $self->{dbh}->ping()) {
    #########
    # flush down any uncommitted transactions & locks
    #
    $self->{dbh}->rollback();
    $self->{dbh}->disconnect();
  }

  return 1;
}

sub create_table {
  my ($self, $t_name, $ref, $t_attrs) = @_;
  my $dbh    = $self->dbh();
  $t_attrs ||= {};
  $ref     ||= {};

  my %values = reverse %{$ref};
  my $pk     = $values{'primary key'};

  if(!$pk) {
    croak qq[Could not determine primary key for table $t_name];
  }

  my @fields = (qq[$pk @{[$self->type_map('primary key')]}]);

  for my $f (grep { $_ ne $pk } keys %{$ref}) {
    push @fields, qq[$f @{[$self->type_map($ref->{$f})]}];
  }

  my $desc  = join q[, ], @fields;
  my $attrs = join q[ ], map { "$_=$t_attrs->{$_}" } keys %{$t_attrs};

  $dbh->do(qq[CREATE TABLE $t_name($desc) $attrs]);
  $dbh->commit();

  return 1;
}

sub drop_table {
  my ($self, $table_name) = @_;
  my $dbh = $self->dbh();

  $dbh->do(qq[DROP TABLE IF EXISTS $table_name]);
  $dbh->commit();

  return 1;
}

sub types {
  return {};
}

sub type_map {
  my ($self, $type) = @_;
  if(!defined $type) {
    return;
  }
  return $self->types->{$type} || $type;
}

sub create {
  return;
}

sub bounded_select {
  my ($self, $query, $start, $len) = @_;
  carp q[bounded_select unimplemented by driver ], ref $self;
  return q[];
}

sub sth_has_warnings {
  my ($self, $sth) = @_;
  return;
}

1;
__END__

=head1 NAME

ClearPress::driver - database driver abstraction layer

=head1 VERSION

$LastChangedRevision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 new_driver

=head2 dbh

=head2 create_table

=head2 drop_table

=head2 create

=head2 type_map - access to a value in the type map, given a key

=head2 types - the whole type map

=head2 bounded_select - stub for select limited by number of rows and first-row position

  my $bounded_select = $driver->bounded_select($unbounded_select, $rows, $start_row);

=head2 sth_has_warnings - arrayref of warning messages from a statement handle, if present

  my $warnings = $driver->sth_has_warnings($sth);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
