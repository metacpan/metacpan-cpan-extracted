package FakeORM::Handle;
use strict;
use warnings;

sub new {
   my ( $class, $table_name, $tdata ) = @_;
   return bless {
      table => $table_name,
      pk    => $tdata->{pk},
      rows  => $tdata->{rows},
      where => undef,
   }, $class;
}

sub where {
   my ( $self, $cond ) = @_;
   return bless { %$self, where => $cond }, ref($self);
}

sub by_id {
   my ( $self, $id ) = @_;
   my $pk = $self->{pk};
   my ($match) = grep { $_->{$pk} eq $id } @{ $self->{rows} };
   return $match;
}

## no critic (Subroutines::ProhibitBuiltinHomonyms)
# Named "all" to match the real DBIx::QuickORM-style handle interface that
# this class stands in for.
sub all {
   my ($self) = @_;
   my @rows   = @{ $self->{rows} };
   my $cond   = $self->{where} or return @rows;
   return grep {
      my $row = $_;
      !grep { !defined( $row->{$_} ) || $row->{$_} ne $cond->{$_} }
         keys %$cond;
   } @rows;
}
## use critic

1;
