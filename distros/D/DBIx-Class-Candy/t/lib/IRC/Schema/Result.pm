package IRC::Schema::Result;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components('Candy');

sub base() { $_[1] || 'IRC::Schema::Result' }

sub perl_version() { return 10 if $] >= 5.010 }
sub autotable() { 1 }
sub gen_table {
   my $self = shift;
   my $ret  = $self->next::method(@_);

   ucfirst $ret
}
1;
