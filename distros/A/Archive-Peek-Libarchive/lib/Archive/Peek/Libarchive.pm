package Archive::Peek::Libarchive;
use strict;
use warnings;
use Object::Tiny qw{ filename };
our $VERSION = '0.37';

require XSLoader;
XSLoader::load( 'Archive::Peek::Libarchive', $VERSION );

sub files {
    my $self     = shift;
    my $filename = $self->filename;
    my @files    = Archive::Peek::Libarchive::_files($filename);
    return @files;
}

sub file {
    my ( $self, $filename ) = @_;
    my $archive_filename = $self->filename;
    my $file
        = Archive::Peek::Libarchive::_file( $archive_filename, $filename );
    return $file;
}

sub iterate {
    my ( $self, $callback ) = @_;
    my $filename = $self->filename;
    Archive::Peek::Libarchive::_iterate( $filename, $callback );
}

1;

__END__

=head1 NAME

Archive::Peek::Libarchive - Peek into archives without extracting them (using libarchive)

=head1 SYNOPSIS

  use Archive::Peek::Libarchive;
  my $peek = Archive::Peek::Libarchive->new( filename => 'archive.tgz' );
  my @files = $peek->files();
  my $contents = $peek->file('README.txt')

  $peek->iterate(
    sub {
      my ( $filename, $contents ) = @_;
      ...
    }
  );

=head1 DESCRIPTION

This module lets you peek into archives without extracting them. This is
a wrapper to the libarchive C libary (http://code.google.com/p/libarchive/),
which you must have installed (libarchive-dev package for Debian/Ubuntu).
It supports many different archive formats and compression algorithms and
is fast.

=head1 METHODS

=head2 new

The constructor takes the filename of the archive to peek into:

  my $peek = Archive::Peek::Libarchive->new( filename => 'archive.tgz' );

=head2 files

Returns the files in the archive:

  my @files = $peek->files();

=head2 file

Returns the contents of a file in the archive:

  my $contents = $peek->file('README.txt')

=head2 iterate

Iterate over all the files in the archive:

  $peek->iterate(
    sub {
      my ( $filename, $contents ) = @_;
      ...
    }
  );

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2011, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or
modify it under the same terms as Perl itself.
