package DBIx::Class::Loader::Writing;

# Empty. POD only.

1;

=head1 NAME                                                                     
                                                                                
DBIx::Class::Loader::Writing - Loader subclass writing guide

=head1 SYNOPSIS

  package DBIx::Class::Loader::Foo;

  # THIS IS JUST A TEMPLATE TO GET YOU STARTED.

  use strict;
  use base 'DBIx::Class::Loader::Generic';
  use Carp;

  sub _db_classes {
      return qw/DBIx::Class::PK::Auto::Foo/;
          # You may want to return more, or less, than this.
  }

  sub _tables {
      my $self = shift;
      my $dbh = $self->{storage}->dbh;
      return $dbh->tables; # Your DBD may need something different
  }

  sub _table_info {
      my ( $self, $table ) = @_;
      ...
      return ( \@cols, \@primary );
  }

  sub _relationships {
      my $self = shift;
      ...
      $self->_belongs_to_many($table, $f_key, $f_table, $f_column);
          # For each relationship you want to set up ($f_column is
          # optional, default is $f_table's primary key)
      ...
  }

=cut
