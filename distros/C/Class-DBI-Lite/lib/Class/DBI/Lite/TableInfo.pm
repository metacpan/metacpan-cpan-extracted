
package Class::DBI::Lite::TableInfo;

use strict;
use warnings 'all';
use Class::DBI::Lite::ColumnInfo;


#==============================================================================
sub new
{
  my ($class, $table) = @_;
  return bless {
    table   => $table,
    columns => [ ]
  }, $class;
}# end new()


#==============================================================================
sub table
{
  $_[0]->{table};
}# end table()


#==============================================================================
sub columns
{
  @{ $_[0]->{columns} };
}# end columns()


#==============================================================================
sub column
{
  my ($s, $name) = @_;
  
  my ($item) = grep { $_->{name} eq $name } @{$s->{columns}};
  return $item;
}# end column()


#==============================================================================
sub add_column
{
  my ($s, %column) = @_;
  
  push @{$s->{columns}}, Class::DBI::Lite::ColumnInfo->new( %column );
}# end add_column()

1;# return true:

=pod

=head1 NAME

Class::DBI::Lite::TableInfo - Utility class for database table meta-information.

=head1 SYNOPSIS

  # Methods:
  my $info = Class::DBI::Lite::TableInfo->new( 'users' );
  $info->add_column(
    name          => 'user_id',
    type          => 'integer',
    length        => 10,
    is_nullable   => 0,
    default_value => undef,
    is_pk         => 1,
    key           => 'primary_key',
  );
  my $col = $info->column( 'user_id' );
  
  # Properties:
  my @cols = $info->columns();
  print $info->table; # "users"

=head1 DESCRIPTION

C<Class::DBI::Lite::TableInfo> provides a consistent means to discover the meta-info about
tables and their fields in a database.

=head1 PUBLIC PROPERTIES

=head2 table

Returns the name of the table.

=head2 columns

Returns a list of L<Class::DBI::Lite::ColumnInfo> objects that pertain to the current table.

=head1 PUBLIC METHODS

=head2 new( $table_name )

Returns a new C<Class::DBI::Lite::TableInfo> object for the table named C<$table_name>.

=head2 column( $name )

Returns a L<Class::DBI::Lite:ColumnInfo> object that matches C<$name>.

=head2 add_column( %args )

Adds a new L<Class::DBI::Lite::ColumnInfo> object to the table's collection.

C<%args> is passed to the L<Class::DBI::Lite::ColumnInfo> constructor and should contain its required parameters.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

L<http://www.devstack.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 John Drago <jdrago_999@yahoo.com>, All Rights Reserved.

This software is Free software and may be used and redistributed under the same
terms as perl itself.

=cut

