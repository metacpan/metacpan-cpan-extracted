package Data::AutoBimap;

use 5.012000;
use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.03';

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

sub new {
  my ($class, %options) = @_;

  $options{start} //= 1;

  my $self = {
    next => $options{start},
    s2n  => {},
    n2s  => [],
  };
  
  bless $self, $class;
}

sub s2n {
  my ($self, $s) = @_;

  unless (exists $self->{s2n}{$s}) {
    $self->{s2n}{$s} = $self->{next};
    $self->{n2s}[$self->{next}] = $s;
    $self->{next}++;
  }

  return $self->{s2n}{$s};
}

sub n2s {
  my ($self, $n) = @_;
  return $self->{n2s}[$n];
}

1;

__END__

=head1 NAME

Data::AutoBimap - Bidirectional map for enumerated strings

=head1 SYNOPSIS

  use Data::AutoBimap;
  my $bm = Data::AutoBimap->new;
  say $bm->s2n("Test"); # "1"
  say $bm->s2n("123");  # "2"
  say $bm->s2n("Test"); # "1"
  say $bm->n2s(1);      # "Test"
  $bm->n2s(3);          # undef

=head1 DESCRIPTION

This module maps scalars to automatically incrementing integer values
and allows to perform reverse lookups of scalars by their associated
integer value.

=head1 METHODS

=over

=item new(%options)

Creates a new C<Data::AutoBimap> object. The only valid option key is
C<start> providing the first value for the enumerator; defaults to C<1>.

=item s2n($scalar)

Returns the number associated with the scalar; if no number has been
associated with the scalar previously, associates the next consecutive
number with the scalar and returns it. The scalar will be used as key
in a hash.

=item n2s($number)

Returns the scalar associated with the number or C<undef> is no scalar
is associated with it.

=back

=head1 EXPORTS

None.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
