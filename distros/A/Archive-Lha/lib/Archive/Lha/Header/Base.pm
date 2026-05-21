package Archive::Lha::Header::Base;

use strict;
use warnings;
use Carp;
use File::Spec;
use File::Spec::Unix;

sub import {
  my $class  = shift;
  my $caller = caller;

  my @accessors = qw(
    method header_top data_top next_header
    encoded_size original_size crc16 timestamp os
  );

  {
    no strict 'refs'; no warnings 'redefine';
    foreach my $name ( @accessors ) {
      *{"$class\::$name"} = sub { shift->{$name} };
    }
    push @{"$caller\::ISA"}, $class;
  }
}

# Map OS identifier to the most likely filename encoding used by that platform.
my %_os_charset = (
  'a' => 'iso-8859-15',  # Amiga
  'M' => 'cp1252',       # MS-DOS / Windows
  'w' => 'cp1252',       # WinNT / Win95
  'U' => 'guess',        # Unix (encoding varies: UTF-8 on modern, latin-1 on older)
  'H' => 'cp932',        # Human68K (Sharp X68000)
  'J' => 'cp932',        # Java VM (often used with Japanese archives)
  'm' => 'UTF-8',        # Macintosh (modern)
);

sub charset_for_os {
  my ($self) = @_;
  my $os_id = $self->{os} ? $self->{os}[0] : undef;
  return $os_id && $os_id ne '?' ? ( $_os_charset{$os_id} // 'guess' ) : 'guess';
}

sub pathname {
  my ($self, $from, $to) = @_;
  my $path;
  if ( $self->{pathname} ) {
    $path = _conv_sep( $self->{pathname} );
  }
  elsif ( $self->{directory} && $self->{filename} ) {
    $path = File::Spec::Unix->catfile(
      _conv_sep( $self->{directory} ),
      _conv_sep( $self->{filename} )
    );
  }
  elsif ( $self->{filename} ) {
    $path = _conv_sep( $self->{filename} );
  }
  elsif ( $self->{directory} ) {
    $path = _conv_sep( $self->{directory} . '/' );
  }

  # avoid traversal
  if ( File::Spec::Unix->file_name_is_absolute( $path ) ) {
    my ($vol, $dir, $file) = File::Spec::Unix->splitpath( $path );
    $path = File::Spec::Unix->catfile( '.', $dir, $file );
  }

  # default from-encoding: auto-detect from OS field
  $from //= $self->charset_for_os;
  $to   //= 'UTF-8';

  require Encode;
  if ( lc $from eq 'guess' ) {
    require Encode::Guess;
    my $enc = Encode::Guess::guess_encoding(
      $path => qw( latin1 latin2 cp932 euc-jp )
    );
    Encode::from_to( $path, ref($enc) ? $enc->name : 'latin1', $to );
  }
  elsif ( lc $from ne lc $to ) {
    Encode::from_to( $path, $from, $to );
  }

  my $trailing_slash = $path =~ m{/$};
  $path = File::Spec::Unix->canonpath( $path );
  $path .= '/' if $trailing_slash && $path !~ m{/$};
  return $path;
}

sub dirname {
  my $self = shift;
  my $path = $self->pathname(@_);
  require File::Basename;
  return  File::Basename::dirname( $path );
}

sub _conv_sep {
  my $path = shift;

  $path =~ s{\xff|\\}{/}g;
  return $path;
}

1;

__END__

=head1 NAME

Archive::Lha::Header::Base

=head1 DESCRIPTION

This provides several common accessors for convenient properties of LHa headers.

=head1 METHODS

=head2 method

returns by which method the file is archived.

=head2 header_top

returns from where the header part of the archived file begins.

=head2 data_top

returns from where the data part of the archived file begins.

=head2 next_header

returns from where the next header part begins.

=head2 encoded_size

returns the encoded/compressed size of the archived file.

=head2 original_size

returns the original size of the archived file.

=head2 crc16

returns CRC-16 value of the archived file.

=head2 timestamp

returns when the archived file was last updated.

=head2 os

returns under which OS the file was archived.

=head2 pathname

returns the canonical form of the pathname of the archived file. If you want native form, see the header's private properties which varies depending on the header level. Also note that the native form uses 0xff as a path separator.

You also can pass encoding options:

  # the pathname should have been encoded as 'euc-jp'
  $header->pathname('euc-jp' => 'shiftjis');

If you are not sure, you can let it guess:

  # original encoding of the path would be guessed
  $header->pathname('guess' => 'shiftjis');

=head2 charset_for_os

Returns the most likely filename encoding for this archive entry based on
the OS identifier byte in the header: C<iso-8859-15> for Amiga (C<a>),
C<cp1252> for MS-DOS/Windows (C<M>/C<w>), C<UTF-8> for Unix (C<U>) and
modern Mac (C<m>), C<cp932> for Human68K/Java (C<H>/C<J>). Returns
C<'guess'> when the OS field is absent or unrecognised, which causes
C<pathname()> to invoke L<Encode::Guess>.

=head2 dirname

returns directory part of the pathname. This is mainly used while creating parent directory for the file.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
