package Alzabo::Runtime::UniqueRowCache;

use strict;

use Alzabo::Runtime::Table;
use Alzabo::Runtime::RowState::InCache;

my %CACHE;

BEGIN
{
    my $real_make_row = \&Alzabo::Runtime::Table::_make_row;

    local $^W = 0;
    *Alzabo::Runtime::Table::_make_row =
        sub { my $self = shift;
              my %p = @_;

              if ( delete $p{no_cache} )
              {
                  return
                      $self->$real_make_row( %p,
                                             state => 'Alzabo::Runtime::RowState::Live',
                                           );
              }

              my $id =
                  Alzabo::Runtime::Row->id_as_string_ext
                      ( pk    => $p{pk},
                        table => $p{table},
                      );

              my $table_name = $p{table}->name;
              return $CACHE{$table_name}{$id} if exists $CACHE{$table_name}{$id};

              my $row =
                  $self->$real_make_row( %p,
                                         state => 'Alzabo::Runtime::RowState::InCache',
                                       );

              return unless $row;

              Alzabo::Runtime::UniqueRowCache->write_to_cache($row);

              return $row;
          };
}

sub clear { %CACHE = () };

sub clear_table { delete $CACHE{ $_[1]->name } }

sub row_in_cache { return $CACHE{ $_[1] }{ $_[2] } }

sub delete_from_cache { delete $CACHE{ $_[1] }{ $_[2] } }

sub write_to_cache { $CACHE{ $_[1]->table->name }{ $_[1]->id_as_string } = $_[1] }

1;

__END__

=head1 NAME

Alzabo::Runtime::UniqueRowCache - Implements a row cache for Alzabo

=head1 SYNOPSIS

  use Alzabo::Runtime::UniqueRowCache;

  Alzabo::Runtime::UniqueRowCache->clear();

=head1 DESCRIPTION

This is a very simple caching mechanism for C<Alzabo::Runtime::Row>
objects that tries to ensure that for there is never more than one row
object in memory for a given database row.

To use it, simply load it.

It can be foiled through the use of C<Storable> or other "deep magic"
cloning code, like in the C<Clone> module.

The cache is a simple hash kept in memory.  If you use this module,
you are responsible for clearing the cache as needed.  The only time
it is cleared automatically is when a table update or delete is
performed, in which case all cached rows for that table are cleared.

In a persistent environment like mod_perl, you should clear the cache
on a regular basis in order to prevent the cache from getting out of
sync with the database.  A good way to do this is to clear it at the
start of every request.

=head1 METHODS

All methods provided are class methods.

=over 4

=item * clear

This clears the entire cache

=item * clear_table( $table_object )

Given a table object, this method clears all the cached rows from that
table.

=item * row_in_cache( $table_name, $row_id )

Given a table I<name> and a row id, as returned by the C<<
Alzabo::Runtime::Row->id_as_string >> method, this method returns the
matching row from the cache, if it exists.  Otherwise it returns undef.

=item * delete_from_cache( $table_name, $row_id )

Given a table I<name> and a row id, as returned by the C<<
Alzabo::Runtime::Row->id_as_string >> method, this method returns the
matching row from the cache.

=item * write_to_cache( $row_object )

Given a row object, this method stores it in the cache.

=back

=head1 AVOIDING THE CACHE

If you want to not cache a row, then you can pass the "no_cache"
parameter to any table or schema method that creates a new row object
or a cursor, such as C<< Alzabo::Runtime::Table->insert() >>, C<<
Alzabo::Runtime::Table->rows_where() >>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
