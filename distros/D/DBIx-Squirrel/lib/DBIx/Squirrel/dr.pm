use strict;
use warnings;

package    # hide from PAUSE
  DBIx::Squirrel::dr;

BEGIN {
    require DBIx::Squirrel
      unless defined($DBIx::Squirrel::VERSION);
    $DBIx::Squirrel::dr::VERSION = $DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::dr::ISA     = 'DBI::dr';
}

use namespace::autoclean;

sub _root_class {
    my $root_class = ref($_[0]) || $_[0];
    $root_class =~ s/::\w+$//;
    return RootClass => $root_class
      if wantarray;
    return $root_class;
}

sub _clone_connection {
    my $invocant = shift;
    return
      unless UNIVERSAL::isa($_[0], 'DBI::db');
    my $connection = shift;
    my $attributes = @_ && UNIVERSAL::isa($_[$#_], 'HASH') ? pop : {};
    return $connection->clone({%{$attributes}, __PACKAGE__->_root_class});
}

sub connect {
    goto &_clone_connection
      if UNIVERSAL::isa($_[1], 'DBI::db');
    my $invocant   = shift;
    my $attributes = @_ && UNIVERSAL::isa($_[$#_], 'HASH') ? pop : {};
    return $invocant->DBI::connect(@_, {%{$attributes}, __PACKAGE__->_root_class});
}

sub connect_cached {
    my $invocant   = shift;
    my $attributes = @_ && UNIVERSAL::isa($_[$#_], 'HASH') ? pop : {};
    return $invocant->DBI::connect_cached(@_, {%{$attributes}, __PACKAGE__->_root_class});
}

1;
