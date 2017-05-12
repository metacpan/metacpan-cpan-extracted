package IRC::Schema::Candy;

use base 'DBIx::Class::Candy';

sub base() { $_[1] || 'IRC::Schema::Result' }

sub perl_version() { return 10 if $] >= 5.010 }
sub experimental() { return ['signatures'] if $] >= 5.020 }
sub autotable() { 1 }
sub gen_table {
   my $self = shift;
   my $ret  = $self->next::method(@_);

   ucfirst $ret
}

1;
