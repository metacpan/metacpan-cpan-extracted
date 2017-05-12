package APR::HTTP::Headers::Compat::MagicHash;

use strict;
use warnings;

use APR::HTTP::Headers::Compat::MagicArray;
use APR::Table;
use Carp qw( confess );
use HTTP::Headers;
use Storable qw( dclone );

=head1 NAME

APR::HTTP::Headers::Compat::MagicHash - Tie a hash to an APR::Table

=cut

sub TIEHASH {
  my ( $class, $table, %args ) = @_;

  my $self = bless { table => $table }, $class;

  while ( my ( $k, $v ) = each %args ) {
    $self->STORE( $k, $v );
  }

  return $self;
}

=head2 C<< table >>

Get the table object.

=cut

sub table { shift->{table} }

sub _nicename {
  my ( $self, @names ) = @_;

  my $hdr    = HTTP::Headers->new( map { $_ => 1 } @names );
  my @nice   = $hdr->header_field_names;
  my %lookup = map { lc $_ => $_ } @nice;
  my @r = map { $lookup{$_} or confess "No mapping for $_" } @names;
  return wantarray ? @r : $r[0];
}

sub _nicefor {
  my ( $self, $name ) = @_;
  return $1 if $name =~ /^:(.+)/;
  return $self->{namemap}{$name} ||= $self->_nicename( $name );
}

sub FETCH {
  my ( $self, $key ) = @_;
  my $nkey = $self->_nicefor( $key );
  my @vals = $self->table->get( $nkey );
  return $vals[0] if @vals < 2;
  tie my @r, 'APR::HTTP::Headers::Compat::MagicArray', $nkey, $self,
   @vals;
  return \@r;
  #  return $self->{hash}{$nkey};
}

sub STORE {
  my ( $self, $key, $value ) = @_;
  my $nkey = $self->_nicefor( $key );
  $self->{rmap}{$nkey} = $key;

  my $table = $self->table;
  my @vals = 'ARRAY' eq ref $value ? @$value : $value;
  $table->set( $nkey, shift @vals );
  $table->add( $nkey, $_ ) for @vals;
  $self->_changed;
}

sub DELETE {
  my ( $self, $key ) = @_;
  my $nkey = $self->_nicefor( $key );
  my $rv   = $self->FETCH( $key );
  $self->table->unset( $nkey );
  $self->_changed;
  return $rv;
}

sub CLEAR {
  my ( $self ) = @_;
  $self->table->clear;
  $self->_changed;
}

sub EXISTS {
  my ( $self, $key ) = @_;
  my %fld = map { $_ => 1 } $self->_keys;
  return exists $fld{$key};
}

sub _mkkeys {
  my $self = shift;
  my @k    = ();
  my $rm   = $self->{rmap};
  my %seen = ();
  $self->table->do(
    sub {
      my ( $k, $v ) = @_;
      my $kk = defined $rm->{$k} ? $rm->{$k} : lc $k;
      push @k, $kk unless $seen{$kk}++;
    } );
  return \@k;
}

sub _keys {
  my $self = shift;
  return @{ $self->{keys} ||= $self->_mkkeys };
}

sub _changed {
  my $self = shift;
  delete $self->{keys};
}

sub FIRSTKEY {
  my ( $self ) = @_;
  $self->{pos} = 0;
  return ( $self->_keys )[0];
}

sub NEXTKEY {
  my ( $self, $lastkey ) = @_;
  my @keys = $self->_keys;
  unless ( $keys[ $self->{pos} ] eq $lastkey ) {
    my $nk = scalar @{ $self->{keys} };
    for my $i ( 0 .. $nk ) {
      if ( $keys[$i] eq $lastkey ) {
        $self->{pos} = $i;
        last;
      }
    }
  }
  return $keys[ ++$self->{pos} ];
}

sub SCALAR {
  my ( $self ) = @_;
  return scalar $self->_keys;
}

sub DESTROY {
  my ( $self ) = @_;
  #    use Data::Dumper;
  #    print STDERR "# ", Dumper($self);
  #  print STDERR "# <<<\n";
  #  $self->table->do(
  #    sub {
  #      my ( $k, $v ) = @_;
  #      print STDERR "# $k => $v\n";
  #    } );
  #  print STDERR "# >>>\n";
}

sub UNTIE { }

1;

# vim:ts=2:sw=2:sts=2:et:ft=perl
