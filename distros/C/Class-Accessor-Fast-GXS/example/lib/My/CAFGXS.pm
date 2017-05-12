package My::CAFGXS;
use strict;
use warnings;
use base qw(Class::Accessor::Fast::GXS);
__PACKAGE__->mk_ro_accessors('ro');
__PACKAGE__->mk_wo_accessors('wo_one','wo_multi');
__PACKAGE__->mk_accessors('both');

1;
