package DBIx::Class::Sims::REST::SQLite;

use 5.010_000;

use strict;
use warnings FATAL => 'all';

use DBIx::Class::Sims::REST;
use base 'DBIx::Class::Sims::REST';

sub get_connect_string {
  my $class = shift;
  my ($item, $defaults) = @_;

  my $name = $item->{database}{name} // return;
  return "dbi:SQLite:dbname=${name}";
}

sub get_create_commands {}

1;
__END__
