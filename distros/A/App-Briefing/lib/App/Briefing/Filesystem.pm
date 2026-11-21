package App::Briefing::Filesystem;
# ABSTRACT: Unicode-safe filesystem access for App::Briefing

use Moo;
use Encode qw( FB_CROAK decode encode );
use Path::Tiny qw( path );
use utf8 ();
use if $^O eq 'MSWin32', 'Win32';
use if $^O eq 'MSWin32', 'Win32::LongPath';
use namespace::clean;

our $VERSION = '0.006000';

sub is_windows { $^O eq 'MSWin32' }


sub decode_path {
  my ( $self, $value ) = @_;
  return $value unless defined $value;
  return $value if utf8::is_utf8($value);

  my $decoded = eval { decode( 'UTF-8', $value, FB_CROAK ) };
  return $@ ? $value : $decoded;
}


sub environment_value {
  my ( $self, $name ) = @_;
  my $value = $ENV{$name};
  return unless defined $value && length $value;

  if ($self->is_windows) {
    my $wide = $self->_wide_environment_value($name);
    return $wide if defined $wide && length $wide;
  }
  return $self->decode_path($value);
}


sub _wide_environment_value {
  my ( $self, $name ) = @_;
  # Win32::ExpandEnvironmentStrings expands against the wide environment and
  # returns ANSI code page bytes when every character fits that code page, a
  # UTF-8 character string otherwise (wstr_to_sv in Win32.xs, Win32 0.59). The
  # leading noncharacter U+FFFF fits no ANSI code page, so a usable result is
  # always the character string. An unset variable stays unexpanded; under the
  # UTF-8 code page 65001 the result is undef or bytes, and %ENV, which holds
  # UTF-8 there, is used instead.
  my $reference = "\x{FFFF}".'%'.$name.'%';
  my $expanded = Win32::ExpandEnvironmentStrings($reference);
  return unless defined $expanded && utf8::is_utf8($expanded);
  return if $expanded eq $reference;
  return unless $expanded =~ s/\A\x{FFFF}//;
  return $expanded;
}

sub _native_path {
  my ( $self, $value ) = @_;
  return $value
    if $self->is_windows || !defined $value || !utf8::is_utf8($value);

  my $encoded = eval { encode( 'UTF-8', $value, FB_CROAK ) };
  return $@ ? $value : $encoded;
}

sub join_path {
  my ( $self, @parts ) = @_;
  return '' unless @parts;

  my $joined = shift @parts;
  for my $part (@parts) {
    next unless defined $part && length $part;
    $joined = path($part)->is_absolute
      ? $part
      : path( $joined, $part )->stringify;
  }
  return path($joined)->stringify;
}


sub parent {
  my ( $self, $file ) = @_;
  return path($file)->parent->stringify;
}


sub basename {
  my ( $self, $file ) = @_;
  return path($file)->basename;
}


sub is_absolute {
  my ( $self, $file ) = @_;
  return path($file)->is_absolute ? 1 : 0;
}


sub current_dir {
  my ( $self ) = @_;
  my $directory = $self->is_windows
    ? Win32::LongPath::getcwdL()
    : path('.')->absolute->stringify;
  return $self->decode_path($directory);
}


sub absolute {
  my ( $self, $file ) = @_;
  my $absolute = $self->is_windows
    ? Win32::LongPath::abspathL($file)
    : $self->normalize( path($file)->absolute->stringify );
  return $self->decode_path($absolute);
}


sub exists {
  my ( $self, $file ) = @_;
  return Win32::LongPath::testL( 'e', $file ) ? 1 : 0
    if $self->is_windows;
  return path($file)->exists ? 1 : 0;
}


sub is_file {
  my ( $self, $file ) = @_;
  return Win32::LongPath::testL( 'f', $file ) ? 1 : 0
    if $self->is_windows;
  return path($file)->is_file ? 1 : 0;
}


sub is_dir {
  my ( $self, $file ) = @_;
  return Win32::LongPath::testL( 'd', $file ) ? 1 : 0
    if $self->is_windows;
  return path($file)->is_dir ? 1 : 0;
}


sub is_dangling_symlink {
  my ( $self, $file ) = @_;
  return 0 if $self->is_windows;
  my $native = $self->_native_path($file);
  return -l $native && !-e $native ? 1 : 0;
}


sub is_readable_file {
  my ( $self, $file ) = @_;
  return 0 unless $self->is_file($file);

  my $fh;
  my $opened = $self->is_windows
    ? Win32::LongPath::openL( \$fh, '<:encoding(UTF-8)', $file )
    : eval { $fh = path($file)->openr_utf8; 1 };
  return 0 unless $opened && $fh;
  close $fh;
  return 1;
}


sub _universal_newlines {
  my ( $self, $text ) = @_;
  $text = '' unless defined $text;
  $text =~ s/\r\n?/\n/g;
  return $text;
}

sub slurp_utf8 {
  my ( $self, $file ) = @_;
  return '' unless $self->is_file($file);

  if ($self->is_windows) {
    my $fh;
    return '' unless Win32::LongPath::openL(
      \$fh,
      '<:encoding(UTF-8)',
      $file,
    );
    local $/;
    my $text = <$fh>;
    close $fh;
    return $self->_universal_newlines($text);
  }

  my $text = eval { path($file)->slurp_utf8 };
  return $self->_universal_newlines($text);
}


sub spew_utf8 {
  my ( $self, $file, $text ) = @_;

  if ($self->is_windows) {
    my $fh;
    # openL keeps the default :crlf layer; :raw matches Path::Tiny's LF bytes.
    return 0 unless Win32::LongPath::openL(
      \$fh,
      '>:raw:encoding(UTF-8)',
      $file,
    );
    my $ok = print {$fh} $text;
    $ok = close($fh) && $ok;
    return $ok ? 1 : 0;
  }

  return eval { path($file)->spew_utf8($text); 1 } ? 1 : 0;
}


sub make_path {
  my ( $self, $directory ) = @_;
  return 1 if $self->is_dir($directory);

  if ($self->is_windows) {
    my $parent = $self->parent($directory);
    return 0
      if $parent ne $directory
      && !$self->is_dir($parent)
      && !$self->make_path($parent);
    return 1 if Win32::LongPath::mkdirL($directory);
    return $self->is_dir($directory);
  }

  return eval { path($directory)->mkpath; 1 } ? 1 : 0;
}


sub children {
  my ( $self, $directory ) = @_;
  return [] unless $self->is_dir($directory);

  if ($self->is_windows) {
    my $dir = Win32::LongPath->new;
    return [] unless $dir->opendirL($directory);
    my @entries = $dir->readdirL;
    $dir->closedirL;
    return [
      sort
      map { $self->decode_path($_) }
      grep { $_ ne '.' && $_ ne '..' }
      @entries
    ];
  }

  my $native_directory = $self->_native_path($directory);
  my @children = eval { path($native_directory)->children };
  return [] if $@;
  return [ sort map { $self->decode_path( $_->basename ) } @children ];
}


sub child_directories {
  my ( $self, $directory ) = @_;
  return [
    grep { $self->is_dir($_) }
    map { $self->join_path( $directory, $_ ) }
    @{ $self->children($directory) }
  ];
}


sub walk_files {
  my ( $self, $root, $suffix ) = @_;
  return [] unless $self->is_dir($root);

  my @files;
  $self->_walk_files_into( \@files, $root, $suffix );
  return \@files;
}


sub _walk_files_into {
  my ( $self, $files, $directory, $suffix ) = @_;
  my @directories;
  for my $name (@{ $self->children($directory) }) {
    my $entry = $self->join_path( $directory, $name );
    if ($self->is_dir($entry)) {
      push @directories, $entry;
    }
    elsif ($self->is_file($entry) && $name =~ /\Q$suffix\E\z/) {
      push @{$files}, $entry;
    }
  }
  $self->_walk_files_into( $files, $_, $suffix ) for @directories;
  return;
}

sub normalize {
  my ( $self, $file ) = @_;
  my $value = defined $file ? $file : '';

  my $prefix = '';
  if ($self->is_windows) {
    $value =~ tr{\\}{/};
    if ($value =~ s{\A([A-Za-z]:)(?:/+)?}{}) {
      $prefix = $1.'/';
    }
    elsif ($value =~ s{\A/+}{}) {
      $prefix = '/';
    }
  }
  elsif ($value =~ s{\A/+}{}) {
    $prefix = '/';
  }

  my @parts;
  for my $part (split m{/+}, $value) {
    next if $part eq '' || $part eq '.';
    if ($part eq '..') {
      if (@parts && $parts[-1] ne '..') {
        pop @parts;
        next;
      }
      push @parts, $part unless $prefix;
      next;
    }
    push @parts, $part;
  }

  my $normalized = $prefix.join '/', @parts;
  $normalized = '/' if $normalized eq '' && $prefix eq '/';
  $normalized = lc $normalized if $self->is_windows;
  return $normalized;
}


sub within {
  my ( $self, $file, $root ) = @_;
  my $normalized_file = $self->normalize($file);
  my $normalized_root = $self->normalize($root);
  return 1 if $normalized_file eq $normalized_root;
  my $prefix = $normalized_root eq '/' ? '/' : $normalized_root.'/';
  return index( $normalized_file, $prefix ) == 0 ? 1 : 0;
}


sub relative {
  my ( $self, $file, $root ) = @_;
  return path($file)->relative($root)->stringify;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Briefing::Filesystem - Unicode-safe filesystem access for App::Briefing

=head1 VERSION

version 0.006000

=head1 DESCRIPTION

Every file access and environment read of L<App::Briefing> goes through this
adapter. Paths go in and come out as character strings. POSIX systems use
L<Path::Tiny>. Windows uses explicit L<Win32::LongPath> operations, so Unicode
and long paths never pass through Perl's ordinary file tests or C<open>, and
reads the environment through the wide API. It installs no global filesystem
overrides.

An App::Briefing object takes another adapter through its C<filesystem>
attribute; it has to provide the methods below.

=head2 is_windows

    $filesystem->is_windows

True on Windows (C<MSWin32>), where file access goes through
L<Win32::LongPath> and the environment is read through the wide API.

=head2 decode_path

    my $path = $filesystem->decode_path($bytes);

Returns a path as a character string: bytes that are valid UTF-8 are decoded,
anything else, including a string that is already decoded, comes back as it is.

=head2 environment_value

    my $home = $filesystem->environment_value('HOME');

Returns the environment variable as a character string, or undef when it is
unset or empty. On Windows the value comes from the process's wide environment,
so characters of the ANSI code page, whichever it is, arrive as characters
rather than code page bytes. Characters outside that code page are already
C<?> in that environment by the time Perl code runs (seen with Strawberry
Perl) and cannot be recovered. Elsewhere, and on Windows when the wide read
yields nothing, the C<%ENV> bytes are decoded as UTF-8 and kept as they are
when they are not.

=head2 join_path

    my $file = $filesystem->join_path( $root, '.claude', 'agents' );

Joins path parts. After the first part, empty and undefined parts are skipped,
and an absolute part replaces everything before it. The first part is never
skipped: if it is empty or undefined, the call dies with Path::Tiny's
C<Path::Tiny paths require defined, positive-length parts> unless the next
defined, non-empty part is absolute and so replaces it
(C<join_path('', '/abs')> returns C</abs>). Without any part it returns the
empty string.

=head2 parent

    my $directory = $filesystem->parent($file);

Returns the parent directory of a path.

=head2 basename

    my $name = $filesystem->basename($file);

Returns the last component of a path.

=head2 is_absolute

    $filesystem->is_absolute($path)

True for an absolute path.

=head2 current_dir

    my $cwd = $filesystem->current_dir;

Returns the process's current directory as a character string; on Windows it
is read with the wide API.

=head2 absolute

    my $absolute = $filesystem->absolute($path);

Returns the absolute form of a path, relative to the current directory. On
POSIX systems C<.> and C<..> are folded lexically, as in L</normalize>.

=head2 exists

    $filesystem->exists($path)

True when the path exists.

=head2 is_file

    $filesystem->is_file($path)

True for a plain file.

=head2 is_dir

    $filesystem->is_dir($path)

True for a directory.

=head2 is_dangling_symlink

    $filesystem->is_dangling_symlink($path)

True for a symbolic link whose target does not exist. Always false on
Windows.

=head2 is_readable_file

    $filesystem->is_readable_file($path)

True for a plain file that can be opened for reading.

=head2 slurp_utf8

    my $text = $filesystem->slurp_utf8($file);

Returns a file's content decoded from UTF-8, with C<\r\n> and C<\r> turned
into C<\n>; an empty string when it is not a file or cannot be read.

=head2 spew_utf8

    $filesystem->spew_utf8( $file, $text );

Writes text to a file as UTF-8, replacing its content. Returns true on
success.

=head2 make_path

    $filesystem->make_path($directory);

Creates a directory and any missing parents. Returns true when the directory
exists afterwards.

=head2 children

    my $names = $filesystem->children($directory);

Returns an array reference of the names in a directory, sorted, without
C<.> and C<..>; empty when the path is not a readable directory.

=head2 child_directories

    my $directories = $filesystem->child_directories($directory);

Returns an array reference of the paths of a directory's subdirectories, in
name order.

=head2 walk_files

    my $files = $filesystem->walk_files( $root, '.toml' );

Returns an array reference of the paths of every file below C<$root>, at any
depth, whose name ends in the suffix. A directory's own files come before
those of its subdirectories.

=head2 normalize

    my $key = $filesystem->normalize($path);

Returns a path for comparison: repeated separators, C<.> and C<..> folded
lexically. On Windows backslashes also become slashes and the result is lower
case.

=head2 within

    $filesystem->within( $file, $root )

True when C<$file> is C<$root> or lies below it, compared after
L</normalize>.

=head2 relative

    my $relative = $filesystem->relative( $file, $root );

Returns C<$file> relative to C<$root>.

=head1 SEE ALSO

=over

=item * L<App::Briefing>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/briefing/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
