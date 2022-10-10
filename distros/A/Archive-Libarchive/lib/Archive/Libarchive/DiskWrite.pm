package Archive::Libarchive::DiskWrite;

use strict;
use warnings;
use 5.020;
use Archive::Libarchive::Lib;
use FFI::Platypus::Buffer qw( scalar_to_buffer );
use experimental qw( signatures );
use parent qw( Archive::Libarchive::ArchiveWrite );

# ABSTRACT: Libarchive disk write class
our $VERSION = '0.08'; # VERSION

my $ffi = Archive::Libarchive::Lib->ffi;


$ffi->mangler(sub ($name) { "archive_write_$name"  });

$ffi->attach( [ disk_new => 'new' ] => [] => 'opaque' => sub {
  my($xsub, $class) = @_;
  my $ptr = $xsub->();
  bless { ptr => $ptr }, $class;
});

require Archive::Libarchive::Lib::DiskWrite unless $Archive::Libarchive::no_gen;


$ffi->attach( [data_block => 'write_data_block'] => ['archive_write', 'opaque', 'size_t', 'sint64'] => 'ssize_t' => sub {
  my $xsub = shift;
  my($ptr, $size) = scalar_to_buffer ${$_[1]};
  $xsub->($_[0], $ptr, $size, $_[2]);
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::DiskWrite - Libarchive disk write class

=head1 VERSION

version 0.08

=head1 SYNOPSIS

 use 5.020;
 use Archive::Libarchive qw( :const );
 
 my $dw = Archive::Libarchive::DiskWrite->new;
 $dw->disk_set_options(ARCHIVE_EXTRACT_TIME);
 
 my $text = "Hello World!\n";
 
 my $e = Archive::Libarchive::Entry->new;
 $e->set_pathname("hello.txt");
 $e->set_filetype('reg');
 $e->set_size(length $text);
 $e->set_mtime(time);
 $e->set_mode(oct('0644'));
 
 $dw->write_header($e);
 $dw->write_data(\$text);
 $dw->finish_entry;

=head1 DESCRIPTION

This class represents an instance for writing from an archive to disk.

=head1 CONSTRUCTOR

=head2 new

 # archive_write_disk_new
 my $dw = Archive::Libarchive::DiskWrite->new;

Create a new disk write object.

=head1 METHODS

This is a subset of total list of methods available to all archive classes.
For the full list see L<Archive::Libarchive::API/Archive::Libarchive::DiskWrite>.

=head2 write_data_block

 # archive_write_data_block
 my $ssize_t = $dw->write_data_block(\$buffer, $offset);

Write the entry content data to the disk.  This is intended to be used with L<Archive::Libarchive::ArchiveRead/read_data_block>.

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive::Peek>

Provides an interface for listing and retrieving entries from an archive without extracting them to the local filesystem.

=item L<Archive::Libarchive::Extract>

Provides an interface for extracting arbitrary archives of any format/filter supported by C<libarchive>.

=item L<Archive::Libarchive::Unwrap>

Decompresses / unwraps files that have been compressed or wrapped in any of the filter formats supported by C<libarchive>

=item L<Archive::Libarchive>

This is the main top-level module for using C<libarchive> from
Perl.  It is the best place to start reading the documentation.
It pulls in the other classes and C<libarchive> constants so
that you only need one C<use> statement to effectively use
C<libarchive>.

=item L<Archive::Libarchive::API>

This contains the full and complete API for all of the L<Archive::Libarchive>
classes.  Because C<libarchive> has hundreds of methods, the main documentation
pages elsewhere only contain enough to be useful, and not to overwhelm.

=item L<Archive::Libarchive::Archive>

The base class of all archive classes.  This includes some common error
reporting functionality among other things.

=item L<Archive::Libarchive::ArchiveRead>

This class is used for reading from archives.

=item L<Archive::Libarchive::ArchiveWrite>

This class is for creating new archives.

=item L<Archive::Libarchive::DiskRead>

This class is for reading L<Archive::Libarchive::Entry> objects from disk
so that they can be written to L<Archive::Libarchive::ArchiveWrite> objects.

=item L<Archive::Libarchive::Entry>

This class represents a file in an archive, or on disk.

=item L<Archive::Libarchive::EntryLinkResolver>

This class exposes the C<libarchive> link resolver API.

=item L<Archive::Libarchive::Match>

This class exposes the C<libarchive> match API.

=item L<Dist::Zilla::Plugin::Libarchive>

Build L<Dist::Zilla> based dist tarballs with libarchive instead of the built in L<Archive::Tar>.

=item L<Alien::Libarchive3>

If a suitable system C<libarchive> can't be found, then this
L<Alien> will be installed to provide it.

=item L<libarchive.org|http://libarchive.org/>

The C<libarchive> project home page.

=item L<https://github.com/libarchive/libarchive/wiki>

The C<libarchive> project wiki.

=item L<https://github.com/libarchive/libarchive/wiki/ManualPages>

Some of the C<libarchive> man pages are listed here.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021,2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
