#!perl
package Tuit;

use Class::Persist;
use DBI;

use warnings;
use strict;

use base qw( Class::Persist );

__PACKAGE__->db_table('test' .$$ . int(rand(1000)). 'Tuit');
__PACKAGE__->db_fields(qw(Colour Mass));
__PACKAGE__->mk_accessors(qw(Colour Mass));

sub db_fields_spec {
  shift->SUPER::db_fields_spec, (
  'Colour VARCHAR(63)',
  'Mass VARCHAR(63)',
) }

1;
__END__
=head1 Test class for Class::Persist
