
package My::Model;

use strict;
use warnings 'all';
use base 'Class::DBI::Lite::SQLite';

__PACKAGE__->connection(
  'DBI:SQLite:dbname=t/testdb',
  '',
  ''
);

sub set_up_table
{
  my $s = shift;
  
  $s->SUPER::set_up_table( @_ );
  
  if( $s->find_column('city_name') )
  {
    $s->add_trigger( before_create => sub {
      my $s = shift;
      $s->city_name( ucfirst( $s->city_name ) );
    });
  }# end if()
}# end set_up_table()

1;# return true:

