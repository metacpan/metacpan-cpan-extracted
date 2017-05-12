package DBIx::Class::Sims::REST::MySQL;

use 5.010_000;

use strict;
use warnings FATAL => 'all';

use DBIx::Class::Sims::REST;
use base 'DBIx::Class::Sims::REST';

sub get_connect_string {
  my $class = shift;
  my ($item, $defaults, $opts) = @_;
  $opts //= {};

  # Cannot connect to a database that doesn't exist, even if the first action is
  # to create that database.
  return "dbi:mysql:" if $opts->{no_name};

  my $name = $item->{database}{name} // return;
  return "dbi:mysql:database=${name}";
}

sub get_create_commands {
  my $class = shift;
  my ($item, $defaults) = @_;

  my $user = $item->{database}{username} // $defaults->{database}{username};
  my $pass = $item->{database}{password} // $defaults->{database}{password};
  my $name = $item->{database}{name} // return;

  return (
    "DROP DATABASE IF EXISTS `$name`",
    "CREATE DATABASE `$name`",
    "GRANT ALL ON $name.* TO '$user'\@'%' IDENTIFIED BY '$pass'",
    # MySQL requires localhost to be granted separately.
    "GRANT ALL ON $name.* TO '$user'\@'localhost' IDENTIFIED BY '$pass'",
  );
}

1;
__END__
