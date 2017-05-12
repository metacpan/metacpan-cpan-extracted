use 5.010;    # pack >
use strict;
use warnings;

package Color::Swatch::ASE::Writer;

our $VERSION = '0.001003';

# ABSTRACT: Low level ASE ( Adobe Swatch Exchange ) file Writer.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Encode qw(encode);

## no critic (ValuesAndExpressions::ProhibitEscapedCharacters)
my $BLOCK_GROUP_START = "\x{c0}\x{01}";
my $BLOCK_GROUP_END   = "\x{c0}\x{02}";
my $BLOCK_COLOR       = "\x{00}\x{01}";
my $UTF16NULL         = "\x{00}\x{00}";
## use critic







sub write_string {
  my ( $class, $struct ) = @_;
  my $out = q[];
  $class->_write_signature( \$out, $struct->{signature} );
  $class->_write_version( \$out, @{ $struct->{version} || [ 1, 0 ] } );
  my @blocks = @{ $struct->{blocks} };

  $class->_write_num_blocks( \$out, scalar @blocks );

  for my $block ( 0 .. $#blocks ) {
    $class->_write_block( \$out, $blocks[$block] );
  }

  return $out;
}







sub write_filehandle {
  my ( $class, $filehandle, $structure ) = @_;
  return print {$filehandle} $class->write_string($structure);
}







sub write_file {
  my ( $class, $filename, $structure ) = @_;
  require Path::Tiny;
  return Path::Tiny::path($filename)->spew_raw( $class->write_string($structure) );
}

sub _write_signature {
  my ( undef, $string, $signature ) = @_;
  $signature = 'ASEF' if not defined $signature;
  if ( 'ASEF' ne $signature ) {
    die 'Signature must be ASEF';
  }
  ${$string} .= $signature;
  return;
}

sub _write_bytes {
  my ( undef, $string, $length, $bytes, $format ) = @_;
  my @bytes;
  if ( ref $bytes ) {
    @bytes = @{$bytes};
  }
  else {
    @bytes = ($bytes);
  }
  my $append = q[];
  if ( not defined $format ) {
    $append .= $_ for @bytes;
  }
  else {
    $append = pack $format, @bytes;
  }
  if ( ( length $append ) ne $length ) {
    warn 'Pack length did not match expected pack length!';
  }
  if ( $ENV{TRACE_ASE} ) {
    *STDERR->printf( q[%s : %s %s = ], [ caller 1 ]->[3], $length, ( $format ? $format : q[] ) );
    *STDERR->printf( q[%02x ], ord ) for split //msx, $append;
    *STDERR->printf("\n ");
  }

  ${$string} .= $append;
  return;
}

sub _write_version {
  my ( $self, $string, $version_major, $version_minor ) = @_;
  $version_major = 1 if not defined $version_major;
  $version_minor = 0 if not defined $version_minor;
  $self->_write_bytes( $string, 4, [ $version_major, $version_minor ], q[nn] );
  return;
}

sub _write_num_blocks {
  my ( $self, $string, $num_blocks ) = @_;
  $self->_write_bytes( $string, 4, [$num_blocks], q[N] );
  return;
}

sub _write_block_group {
  my ( $self, $string, $group, $default ) = @_;
  $group = $default if not defined $group;
  $self->_write_bytes( $string, 2, [$group], q[n] );
  return;
}

sub _write_block_label {
  my ( undef, $string, $label ) = @_;
  $label = q[] if not defined $label;
  my $label_chars = encode( 'UTF16-BE', $label, Encode::FB_CROAK );
  $label_chars .= $UTF16NULL;
  if ( $ENV{TRACE_ASE} ) {
    *STDERR->printf( q[%s : = ], [ caller 0 ]->[3] );
    *STDERR->printf( q[%02x ], ord ) for split //msx, $label_chars;
    *STDERR->printf("\n ");
  }

  ${$string} .= $label_chars;
  return;
}

sub _write_group_start {
  my ( $self, $string, $block ) = @_;
  $self->_write_block_group( $string, $block->{group}, 13 );
  $self->_write_block_label( $string, $block->{label} );
  return;
}

sub _write_group_end {
  my ( undef, $string ) = @_;
  ${$string} .= q[];
  return;
}

my $color_table = {
  q[RGB ] => '_write_rgb',
  q[LAB ] => '_write_lab',
  q[CMYK] => '_write_cmyk',
  q[Gray] => '_write_gray',
};

sub _write_color_model {
  my ( $self, $string, $model ) = @_;
  die 'Color model not defined' if not defined $model;
  die "Unknown color model $model" if not exists $color_table->{$model};
  $self->_write_bytes( $string, 4, [$model] );
  return;
}

sub _write_rgb {
  my ( $self, $string, @color ) = @_;
  die 'RGB requires 3 values' if 3 != grep { defined and length } @color;
  $self->_write_bytes( $string, 12, [@color], q[f>f>f>] );
  return;
}

sub _write_lab {
  my ( $self, $string, @color ) = @_;
  die 'LAB requires 3 values' if 3 != grep { defined and length } @color;

  $self->_write_bytes( $string, 12, [@color], q[f>f>f>] );
  return;
}

sub _write_cmyk {
  my ( $self, $string, @color ) = @_;
  die 'CMYK requires 4 values' if 4 != grep { defined and length } @color;
  $self->_write_bytes( $string, 16, [@color], q[f>f>f>f>] );
  return;
}

sub _write_gray {
  my ( $self, $string, @color ) = @_;
  die 'Gray requires 1 value' if 1 != grep { defined and length } @color;
  $self->_write_bytes( $string, 4, [@color], q[f>] );
  return;
}

sub _write_color_type {
  my ( $self, $string, $type ) = @_;
  $type = 2 if not defined $type;
  $self->_write_bytes( $string, 2, [$type], q[n] );
  return;
}

sub _write_color {
  my ( $self, $string, $block ) = @_;
  $self->_write_block_group( $string, $block->{group}, 1 );
  $self->_write_block_label( $string, $block->{label} );
  $self->_write_color_model( $string, $block->{model} );
  my $color_writer = $self->can( $color_table->{ $block->{model} } );
  $self->$color_writer( $string, @{ $block->{values} } );
  $self->_write_color_type( $string, $block->{color_type} );
  return;
}

sub _write_block_type {
  my ( $self, $string, $type ) = @_;
  $self->_write_bytes( $string, 2, [$type] );
  return;
}

sub _write_block_length {
  my ( $self, $string, $length ) = @_;
  $self->_write_bytes( $string, 4, [$length], q[N] );
  return;
}

sub _write_block_payload {
  my ( $self, $string, $block_id, $block_body ) = @_;
  $self->_write_block_type( $string, $block_id );
  $self->_write_block_length( $string, length ${$block_body} );
  ${$string} .= ${$block_body};
  return;
}

sub _write_block {
  my ( $self, $string, $block ) = @_;

  my $block_body = q[];
  if ( 'group_start' eq $block->{type} ) {
    $self->_write_group_start( \$block_body, $block );
    $self->_write_block_payload( $string, $BLOCK_GROUP_START, \$block_body );
    return;
  }
  if ( 'group_end' eq $block->{type} ) {
    $self->_write_group_end( \$block_body, $block );
    $self->_write_block_payload( $string, $BLOCK_GROUP_END, \$block_body );
    return;
  }
  if ( 'color' eq $block->{type} ) {
    $self->_write_color( \$block_body, $block );
    $self->_write_block_payload( $string, $BLOCK_COLOR, \$block_body );
    return;
  }
  die 'Unknown block type ' . $block->{type};
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Swatch::ASE::Writer - Low level ASE ( Adobe Swatch Exchange ) file Writer.

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

  use Color::Swatch::ASE::Writer;
  my $structure = {
    blocks => [
      { type => 'group_start', label => 'My Colour Swatch' },
      { type => 'color', model => 'RGB ', values => [ 0.1 , 0.5, 0.9 ]},
      { type => 'color', model => 'RGB ', values => [ 0.9 , 0.5, 0.1 ]},
      { type => 'group_end' },
    ]
  };

  Color::Swatch::ASE::Writer->write_file(q[./myfile.ase], $structure );

This at present is very low-level simple structure encoding, and is probably not useful to most people.

Its based on the reverse-engineered specification of Adobe™'s "Swatch Exchange" format, which can be found documented many places:

=over 4

=item * L<selpa.net: file formats|http://www.selapa.net/swatches/colors/fileformats.php>

=item * L<colourlovers.com: ase file maker|http://www.colourlovers.com/ase.phps>

=item * L<forums.adobe.com: ase file format reverse engineering|https://forums.adobe.com/thread/322021?start=0&tstart=0>

=back

=head1 METHODS

=head2 C<write_string>

  my $string = Color::Swatch::ASE::Writer->write_string($structure);

=head2 C<write_filehandle>

  Color::Swatch::ASE::Writer->write_filehandle($fh, $structure);

=head2 C<write_file>

  Color::Swatch::ASE::Writer->write_file(q[path/to/file.ase], $structure);

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
