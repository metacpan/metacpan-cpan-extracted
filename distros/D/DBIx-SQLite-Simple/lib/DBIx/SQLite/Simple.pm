#
# $Id: Simple.pm,v 1.14 2007-01-27 13:35:02 gomor Exp $
#
package DBIx::SQLite::Simple;
use strict;
use warnings;
use Carp;

our $VERSION = '0.35';

require DBI;
require Class::Gomor::Array;
our @ISA = qw(Class::Gomor::Array);

our @AS = qw(
   db
   _dbh
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

our $Dbo;

=head1 NAME

DBIx::SQLite::Simple - easy access to SQLite databases using objects

=head1 ATTRIBUTES

=over 4

=item B<db>

Used to store the filename containing the SQLite database.

=back

=head1 METHODS

=over 4

=item B<new>(db => 'filename.db')

Object creator. Takes one argument, and sets the global variable $Dbo to the newly created database handler.

=cut

sub new {
   my $self = shift->SUPER::new(@_);

   confess('Usage: new(db => $db)') unless $self->db;

   my $dbh = DBI->connect(
      'dbi:SQLite:dbname='. $self->db,
      '', '',
      {
         RaiseError => 0,
         PrintError => 0,
         PrintWarn  => 0,
         AutoCommit => 0,
      },
   ) or croak("new: ". $DBI::errstr);

   $self->_dbh($dbh);

   $Dbo = $self;
}

=item B<commit>

Changes made on created database are not automatically commited. You must call this method if you want to commit pending changes.

=cut

sub commit {
   my $self = shift;
   $self->_dbh->commit if $self->_dbh;
}

=item B<close>

When you're done using the database, you can disconnect from it. This method will not commit changes, so do it before closing.

=cut

sub close {
   my $self = shift;
   $self->_dbh->disconnect if $self->_dbh;
   $self->_dbh(undef);
}

sub DESTROY {
   my $self = shift;

   if ($self->_dbh) {
      $self->commit;
      $self->close;
   }
}

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut

1;
