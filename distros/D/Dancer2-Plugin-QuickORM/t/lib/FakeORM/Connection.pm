package FakeORM::Connection;
use strict;
use warnings;
use Carp qw/croak/;

use FakeORM::Table;
use FakeORM::Handle;

sub name   { return $_[0]->{name} }
sub schema { return $_[0] }

sub tables {
   return map { FakeORM::Table->new($_) } sort keys %FakeORM::FIXTURE_TABLES;
}

sub handle {
   my ( $self, $table_name ) = @_;
   my $tdata = $FakeORM::FIXTURE_TABLES{$table_name}
      or croak "FakeORM: no such table '$table_name'";
   return FakeORM::Handle->new( $table_name, $tdata );
}

1;
