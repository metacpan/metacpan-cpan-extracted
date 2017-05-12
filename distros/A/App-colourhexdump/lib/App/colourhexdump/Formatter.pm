use 5.006;    # our
use strict;
use warnings;

package App::colourhexdump::Formatter;

our $VERSION = '1.000003';

# ABSTRACT: Colour-Highlight lines of data as hex.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has );
use String::RewritePrefix;
use Module::Runtime qw( require_module );
use Term::ANSIColor 3.00 qw( colorstrip );

use namespace::autoclean;

has colour_profile => (
  does       => 'App::colourhexdump::ColourProfile',
  is         => 'rw',
  lazy_build => 1,
  init_arg   => undef,
);

has real_colour_profile_class => (
  isa        => 'Str',
  is         => 'rw',
  lazy_build => 1,
  init_arg   => undef,
);

has colour_profile_class => (
  isa      => 'Str',
  is       => 'rw',
  init_arg => 'colour_profile',
  default  => 'DefaultColourProfile',
);

has row_length => (
  isa     => 'Int',
  is      => 'ro',
  default => 32,
);

has chunk_length => (
  isa     => 'Int',
  is      => 'rw',
  default => 4,
);

has hex_row_length => (
  isa        => 'Int',
  is         => 'rw',
  lazy_build => 1,
  init_arg   => undef,
);

__PACKAGE__->meta->make_immutable;
no Moose;

sub _build_hex_row_length {
  my $self = shift;

  # Each byte takes 2 bytes to print.
  #
  if ( $self->chunk_length > $self->row_length ) {
    $self->chunk_length( $self->row_length );
  }
  my $real_chunk_length = $self->chunk_length * 2;

  my $chunks     = int( $self->row_length / $self->chunk_length );
  my $extrachunk = 0;

  if ( ( $chunks * $self->chunk_length ) < $self->row_length ) {
    $extrachunk = $self->row_length - ( $chunks * $self->chunk_length );
  }

  my $whitespaces = $chunks - 1;
  if ( $extrachunk > 0 ) {
    $whitespaces++;
  }

  return ( $chunks * $real_chunk_length ) + $whitespaces + $extrachunk;

}










## no critic ( Subroutines::RequireArgUnpacking )

sub format_foreach_in_fh {
  my ( $self, $fh, $callback ) = ( $_[0], $_[1], $_[2] );
  my $offset = 0;
  while ( read $fh, my $buffer, $self->row_length ) {
    $callback->( $self->format_row( $buffer, $offset ) );
    $offset += $self->row_length;
  }
  return 1;
}







## no critic ( Subroutines::RequireArgUnpacking )

sub format_row_from_fh {
  my ( $self, $fh, $offset ) = ( $_[0], $_[1], $_[2] );
  read $fh, my $buffer, $self->row_length or return;
  my $str = $self->format_row( $buffer, $offset );
  $offset += $self->row_length;
  return $str, $offset;
}







sub format_row {
  my ( $self, $row, $offset ) = @_;

  my $format = "%10s: %s   %s\n";
  my $offset_hex = _to_hex( pack q{N*}, $offset );

  my @chars = split //, $row;

  return sprintf $format, $offset_hex, $self->pad_hex_row( $self->hex_encode(@chars) ), $self->pretty_encode(@chars);
}







sub hex_encode {
  my ( $self, @chars ) = @_;
  my @out;
  while ( my @vals = splice @chars, 0, $self->chunk_length, () ) {
    my $chunk;
    for (@vals) {
      $chunk .= $self->colour_profile->get_string_pre($_);
      $chunk .= _to_hex($_);
      $chunk .= $self->colour_profile->get_string_post($_);
    }
    push @out, $chunk;
  }
  return join q{ }, @out;
}







sub pretty_encode {
  my ( $self, @chars ) = @_;
  my $output;
  for (@chars) {
    $output .= $self->colour_profile->get_string_pre($_);
    $output .= $self->colour_profile->get_display_symbol_for($_);
    $output .= $self->colour_profile->get_string_post($_);
  }
  return $output;
}

sub _to_hex {
  return join q{}, map { unpack q{H*}, $_ } @_;
}







sub pad_hex_row {
  my ( $self, $row ) = @_;
  my $length = length colorstrip($row);
  if ( $length > $self->hex_row_length ) {
    return $row;
  }
  return $row . ( q{ } x ( $self->hex_row_length - $length ) );
}

sub _build_colour_profile {
  my $self = shift;
  require_module( $self->real_colour_profile_class );
  return $self->real_colour_profile_class->new();
}

sub _build_real_colour_profile_class {
  my $self = shift;
  return String::RewritePrefix->rewrite( { q{} => 'App::colourhexdump::', q{=} => q{} }, $self->colour_profile_class );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::colourhexdump::Formatter - Colour-Highlight lines of data as hex.

=head1 VERSION

version 1.000003

=head1 METHODS

=head2 format_foreach_in_fh

    $formatter->format_foreach_in_fh( $fh, sub {
        my $formatted = shift;
        print $formatted;
    });

=head2 format_row_from_fh

    my ( $formatted , $offset ) = $formatter->format_row_from_fh( $fh, $offset );

=head2 format_row

    my $formatted = $formatter->format_row( "Some Characters", $offset );

=head2 hex_encode

    my $hexes = $formatter->hex_encode( split //, "Some Characters" );

=head2 pretty_encode

    my $nicetext = $formatter->pretty_encode( split //, "Some Characters" );

=head2 pad_hex_row

    my $padded = $Formatter->pad_hex_row( $formatter->hex_enode( split //, "Some Characters" ) );

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
