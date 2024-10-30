package IRC::Schema::Candy;

use base 'DBIx::Class::Candy';

sub base() { $_[1] || 'IRC::Schema::Result' }

sub perl_version() { return 34 if $] >= 5.034 }
sub experimental() { return ['try'] if $] >= 5.034 }
sub autotable() { 1 }
sub gen_table {
   my $self = shift;
   my $ret  = $self->next::method(@_);

   ucfirst $ret
}

1;
