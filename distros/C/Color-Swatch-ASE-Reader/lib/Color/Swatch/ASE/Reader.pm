use 5.010;    # unpack >
use strict;
use warnings;

package Color::Swatch::ASE::Reader;

our $VERSION = '0.001004';

# ABSTRACT: Low-Level ASE (Adobe Swatch Exchange) File decoder

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Encode qw( decode );

## no critic (ValuesAndExpressions::ProhibitEscapedCharacters)
my $BLOCK_GROUP_START = "\x{c0}\x{01}";
my $BLOCK_GROUP_END   = "\x{c0}\x{02}";
my $BLOCK_COLOR       = "\x{00}\x{01}";
my $UTF16NULL         = "\x{00}\x{00}";
## use critic







sub read_file {
  my ( $class, $file ) = @_;
  require Path::Tiny;
  return $class->read_string( Path::Tiny::path($file)->slurp_raw );
}







sub read_filehandle {
  my ( $class, $filehandle ) = @_;
  return $class->read_string( scalar <$filehandle> );
}







sub read_string {
  my ( $class, $string ) = @_;
  my $clone = "$string";

  my $signature = $class->_read_signature( \$clone );
  my $version   = $class->_read_version( \$clone );
  my $numblocks = $class->_read_numblocks( \$clone );

  my @blocks;

  for my $id ( 1 .. $numblocks ) {
    push @blocks, $class->_read_block( \$clone, $id, );
  }

  if ( length $clone ) {
    warn +( ( length $clone ) . ' bytes of unhandled data' );
  }

  return { signature => $signature, version => $version, blocks => \@blocks, };

}

sub _read_bytes {
  my ( undef, $string, $num, $decode ) = @_;
  return if ( length ${$string} ) < $num;
  my $chars = substr ${$string}, 0, $num, q[];
  return unpack $decode, $chars if $decode;
  return $chars;
}

sub _read_signature {
  my ( $class, $string ) = @_;
  my $signature = $class->_read_bytes( $string, 4 );
  die 'No ASEF signature' if not defined $signature or q[ASEF] ne $signature;
  return $signature;
}

sub _read_version {
  my ( $class, $string ) = @_;
  my (@version) = $class->_read_bytes( $string, 4, q[nn] );
  die 'No VERSION header' if @version != 2;
  return \@version;
}

sub _read_numblocks {
  my ( $class, $string ) = @_;
  my $blocks = $class->_read_bytes( $string, 4, q[N] );
  die 'No NUM BLOCKS header' if not defined $blocks;
  return $blocks;
}

sub _read_block_group {
  my ( $class, $string ) = @_;
  return $class->_read_bytes( $string, 2, q[n] );
}

sub _read_group_end {
  my ( undef, $group, $label ) = @_;
  return {
    type => 'group_end',
    ( $group ? ( group => $group ) : () ),
    ( $label ? ( label => $label ) : () ),
  };
}

sub _read_group_start {
  my ( undef, $group, $label ) = @_;
  return {
    type => 'group_start',
    ( $group ? ( group => $group ) : () ),
    ( $label ? ( label => $label ) : () ),
  };
}

sub _read_rgb {
  my ( $class, $block_body ) = @_;
  return $class->_read_bytes( $block_body, 12, 'f>f>f>' );
}

sub _read_lab {
  my ( $class, $block_body ) = @_;
  return $class->_read_bytes( $block_body, 12, 'f>f>f>' );
}

sub _read_cmyk {
  my ( $class, $block_body ) = @_;
  return $class->_read_bytes( $block_body, 16, 'f>f>f>f>' );
}

sub _read_gray {
  my ( $class, $block_body ) = @_;
  return $class->_read_bytes( $block_body, 4, 'f>' );
}

my $color_table = {
  q[RGB ] => '_read_rgb',
  q[LAB ] => '_read_lab',
  q[CMYK] => '_read_cymk',
  q[Gray] => '_read_gray',
};

sub _read_color_model {
  my ( $class, $id, $block_body ) = @_;
  my $model = $class->_read_bytes( $block_body, 4 );
  if ( not defined $model ) {
    die "No COLOR MODEL for block $id";
  }
  if ( not exists $color_table->{$model} ) {
    die "Unsupported model $model";
  }
  return $model;
}

sub _read_color_type {
  my ( $class, $block_body ) = @_;
  my $type = $class->_read_bytes( $block_body, 2, q[n] );
  return $type;
}

sub _read_color {
  my ( $class, $id, $group, $label, $block_body ) = @_;

  my $model = $class->_read_color_model( $id, $block_body );

  my @values;

  my $method = $class->can( $color_table->{$model} );
  @values = $class->$method($block_body);

  my $type = $class->_read_color_type($block_body);
  return {
    type => 'color',
    ( $group ? ( group => $group ) : () ),
    ( $label ? ( label => $label ) : () ),
    ( $model ? ( model => $model ) : () ),
    values     => \@values,
    color_type => $type,
  };

}

sub _read_block_label {
  my ( undef,  $string ) = @_;
  my ( $label, $rest )   = ( ${$string} =~ /\A(.*?)${UTF16NULL}(.*\z)/msx );
  if ( defined $rest ) {
    ${$string} = "$rest";
  }
  else {
    ${$string} = q[];
  }
  return decode( 'UTF-16BE', $label, Encode::FB_CROAK );
}

sub _read_block_type {
  my ( $class, $string, $id ) = @_;
  my $type = $class->_read_bytes( $string, 2 );
  die "No BLOCK TYPE for block $id" if not defined $type;
  return $type;
}

sub _read_block_length {
  my ( $class, $string, $id ) = @_;
  my $length = $class->_read_bytes( $string, 4, q[N] );
  die "No BLOCK LENGTH for block $id" if not defined $length;
  if ( ( length ${$string} ) < $length ) {
    warn "Possibly corrupt file, EOF before length $length in block $id";
  }
  return $length;
}

sub _read_block {
  my ( $class, $string, $id, ) = @_;
  my $type   = $class->_read_block_type($string);
  my $length = $class->_read_block_length($string);
  my $block_body;
  my $group;
  my $label;
  if ( $length > 0 ) {
    $block_body = $class->_read_bytes( $string, $length );
    $group      = $class->_read_block_group( \$block_body );
    $label      = $class->_read_block_label( \$block_body );
  }

  if ( $BLOCK_GROUP_END eq $type ) {
    return $class->_read_group_end( $group, $label, );
  }
  if ( $BLOCK_GROUP_START eq $type ) {
    return $class->_read_group_start( $group, $label, );
  }
  if ( $BLOCK_COLOR eq $type ) {
    return $class->_read_color( $id, $group, $label, \$block_body, );
  }
  die "Unknown type $type";

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Color::Swatch::ASE::Reader - Low-Level ASE (Adobe Swatch Exchange) File decoder

=head1 VERSION

version 0.001004

=head1 SYNOPSIS

  use Color::Swatch::ASE::Reader;
  my $hash = Color::Swatch::ASE::Reader->read_file(q[./myfile.ase]);
  print Dumper($hash);

  # {
  #   signature => 'ASEF',
  #   version   => [ 1, 0 ],
  #   blocks    => [
  #     { type => 'group_start', group => 13, label => "My Swatch" },
  #     { type => 'color',
  #         group => 1,  label => "Some Shade",
  #         model => 'RGB ', values => [ 0.9, 0.8, 0.7 ], color_type => 2 },
  #     { type => 'group_end' },
  #   ]
  # }

This at present is very low-level simple structure decoding, and is probably not useful to most people.

Its based on the reverse-engineered specification of Adobe™'s "Swatch Exchange" format, which can be found documented many places:

=over 4

=item * L<selpa.net: file formats|http://www.selapa.net/swatches/colors/fileformats.php>

=item * L<colourlovers.com: ase file maker|http://www.colourlovers.com/ase.phps>

=item * L<forums.adobe.com: ase file format reverse engineering|https://forums.adobe.com/thread/322021?start=0&tstart=0>

=back

=head1 METHODS

=head2 C<read_file>

  my $hash = CSASE::Reader->read_file("path/to/file.ase");

=head2 C<read_filehandle>

  my $hash = CSASE::Reader->read_filehandle($fh);

=head2 C<read_string>

  my $hash = CSASE::Reader->read_string($string);

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
