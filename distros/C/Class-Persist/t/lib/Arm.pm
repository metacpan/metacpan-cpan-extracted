package Arm;
use warnings;
use strict;
use base qw( Limb );

__PACKAGE__->db_table('test' .$$ .  int(rand(1000)). 'Arm');
__PACKAGE__->simple_db_spec(
  elbows => "INT",
  preferred => "CHAR(1)",
);
__PACKAGE__->mk_accessors('elbows', 'preferred');

1;
__END__
=head1 Another test class for Class::Persist
