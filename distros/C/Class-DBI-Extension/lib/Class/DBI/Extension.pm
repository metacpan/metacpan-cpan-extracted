package Class::DBI::Extension;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

=head1 NAME

Class::DBI::Extension - Some extension for Class::DBI

=head1 SYNOPSIS

  package Film;
  use base qw(Class::DBI::Extension);

  # same as Class::DBI, but we have some useful methods.
  package main;

  @film   = Film->retrieve_all;
  @better = Film->retrieve_from_sql('WHERE rating >= ?', 5);
  $mine   = Film->get_count_from_sql('WHERE director = ?', $me);


=head1 DESCRIPTION

THIS RELEASE IS FOR TEMPORARY DEVELOPMENT. Hope this will eventually
be merged into Class::DBI and/or Class::DBI::mysql.

Patches, requests, suggestions are welcome in POOP Mailing List,
<poop-group@lists.sourceforge.net>

=head1 METHODS

=over 4

=item $hashref = $record->attributes_hashref;

returns hash-reference of instance attributes.

=cut

use base qw(Class::DBI);
    
sub attributes_hashref {
    my $self = shift;
    my %data = $self->attributes_hash;
    return \%data;
}

=pod

=item %hash = $record->attributes_hash;

returns hash of instance attributes.

=cut

sub attributes_hash {
    my $self = shift;
    return map { $_ => $self->get($_) } $self->columns;
}

=pod

=item @record = Class->retrieve_from_sql($sql, @bind_args);

returns array of instances via SQL WHERE clause. Following example
returns Movies which have higher rating than 5.

  @better_ones = Film->retrieve_from_sql(q{
      WHERE rating >= ?
  }, 5);

=cut

__PACKAGE__->set_sql('GetFromSQL', <<'SQL');
SELECT  %s
FROM    %s
%s
SQL


sub retrieve_from_sql {
    my($class, $sql, @bind_args) = @_;
    my $sth = $class->sql_GetFromSQL(
        join(', ', $class->columns('Essential')),
        $class->table, $sql,
    );
    $sth->execute(@bind_args);
    return map { $class->construct($_) } $sth->fetchall_hash;
}

=pod

=item  @all = Class->retrieve_all;

returns array of all instances in the class. Caveat for memory consumption.

=cut

sub retrieve_all {
    my $class = shift;
    return $class->retrieve_from_sql(); # retrieves all!
}

=pod

=item  @record = Class->retrieve_range($offset, $limit);

returns array of instance by offset and limit. In this example,
No.10-30 are returned. This method might be useful for
paging.

NOTE: Implemented SQL syntax would be specific for MySQL.

CAVEAT: Sort key is hard-coded with PRIMARY KEY of the table.

=cut

sub retrieve_range {
    my($class, $offset, $num) = @_;
    my $sql = sprintf('ORDER BY %s DESC LIMIT ?, ?', $class->columns('Primary'));
    return $class->retrieve_from_sql($sql, int $offset, int $num);
}

=pod

=item $howmany = Class->get_count_from_sql($sql, $bar);

returns the number of instances that matches SQL WHERE clause.

  $num_of_goods = Film->get_count_from_sql(q{
      WHERE rating >= ?
  }, 5);

=cut

sub get_count_from_sql {
    my($class, $sql, @bind_args) = @_;
    my $sth = $class->sql_GetFromSQL(
        'COUNT(*)', $class->table, $sql,
    );
    $sth->execute(@bind_args);
    my $c = $sth->fetch->[0];
    $sth->finish;
    return $c;
}


=pod
 
=item $num_of_records = Class->get_count;

returns the number of all instances of the class.

=cut

sub get_count {
    my $class = shift;
    return $class->get_count_from_sql();
}

=pod

=item Class->lock_table(); Class->unlock_table();

Without transaction support (like MyISAM), we need to lock tables in
some cases.

  Class->lock_table();
  Class->unlock_table();

NOTE: Implemented SQL syntax is specific for MySQL.

=cut

__PACKAGE__->set_sql('LockTable', <<'SQL');
LOCK TABLES %s WRITE
SQL
    ;

sub lock_table {
    my $class = shift;
    $class->sql_LockTable($class->table)->execute;
}


__PACKAGE__->set_sql('UnlockTable', <<'SQL');
UNLOCK TABLES
SQL
    ;

sub unlock_table {
    my $class = shift;
    $class->sql_UnlockTable->execute;
}

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::mysql>

=cut
