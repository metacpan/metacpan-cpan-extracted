#!perl
package Limb;
use warnings;
use strict;
use base qw( Class::Persist );

__PACKAGE__->db_table('test' .$$ .  int(rand(1000)). 'Limb');
__PACKAGE__->simple_db_spec(
  digits => 'INT',
  side => "CHAR(10)",
  tuit => 'Tuit::',
  tuits => ['Tuit'],
  brain_contents => 'BLOB',
);
__PACKAGE__->mk_accessors('digits', 'side', 'tuit', 'tuits', 'brain_contents');
__PACKAGE__->binary_fields('brain_contents');

1;
__END__
=head1 Another test class for Class::Persist
