package Archive::Libarchive::Archive;

use strict;
use warnings;
use 5.020;
use experimental qw( signatures );
use Archive::Libarchive::Entry;

# ABSTRACT: Libarchive archive base object
our $VERSION = '0.07'; # VERSION

my $ffi = Archive::Libarchive::Lib->ffi;


$ffi->mangler(sub ($name) { "archive_$name" });

$ffi->attach( [ entry_new2 => 'entry' ] => ['archive'] => 'opaque' => sub {
  my($xsub, $self) = @_;
  my $ptr = $xsub->($self);
  bless { ptr => $ptr }, 'Archive::Libarchive::Entry';
});


$ffi->attach( clear_error => ['archive'] );
$ffi->attach( errno => ['archive'] => 'int' );
$ffi->attach( error_string => ['archive'] => 'string' );


$ffi->attach( set_error => ['archive', 'int', 'string'] => [] => sub {
  my($xsub, $self, $errno, $string) = @_;
  $xsub->($self, $errno, $string =~ s/%/%%/gr);
});


$ffi->attach( filter_code => ['archive', 'int'] => 'archive_filter_t' );
$ffi->attach( format => ['archive'] => 'archive_format_t' );

require Archive::Libarchive::Lib::Archive unless $Archive::Libarchive::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::Archive - Libarchive archive base object

=head1 VERSION

version 0.07

=head1 SYNOPSIS

 # handle errors correctly.
 my $code = $r->read_data(\$data);
 if($code == ARCHIVE_WARN) {
   warn $r->error_string;
 } elsif($code == ARCHIVE_FAIL || $code == ARCHIVE_FATAL) {
   die $r->error_string;
 }

=head1 DESCRIPTION

This class is a base class for all archive classes in L<Archive::Libarchive>.

=head1 METHODS

This is a subset of total list of methods available to all archive classes.
For the full list see L<Archive::Libarchive::API/Archive::Libarchive::Archive>.

=head2 entry

 # archive_entry_new2
 my $e = $ar->entry;

This method creates a new L<Archive::Libarchive::Entry> instance, like when
you create an instance with that class' L<new|Archive::Libarchive::Entry/new>
method, except this form will pull character-set conversion information from
the specified archive instance.

=head2 errno

 # archive_errno
 my $int = $ar->errno;

Returns the system C<errno> code for the archive instance.  For non-system level
errors, this will not have a sensible value.

=head2 error_string

 # archive_error_string
 my $string = $ar->error_string;

Returns a human readable diagnostic of error for the corresponding archive instance.

=head2 clear_error

 # archive_clear_error
 $ar->clear_error;

Clear the error for the corresponding archive instance.

=head2 set_error

 # archive_set_error
 $ar->set_error($errno, $string);

This will set the C<errno> code and human readable diagnostic for the archive
instance.  Not all errors have a corresponding C<errno> code, so you can
set that to zero (C<0>) in that case.

=head2 filter_code

 # archive_filter_code
 my $code = $ar->filter_code($num);

This will return the filter code at position C<$num>.  For the total
number of positions see the
L<filter_count method|Archive::Libarchive::API/filter_count>.

The constant prefix for this method is C<ARCHIVE_FILTER_>.  This will
return a dualvar where the string is the lowercase name without the
prefix and the integer is the constant value.  For the full list see
L<Archive::Libarchive::API/CONSTANTS>.

=head2 format

 # archive_format
 my $code = $ar->format;

This will return the format code at position C<$num>.

The constant prefix for this method is C<ARCHIVE_FORMAT_>.  This will
return a dualvar where the string is the lowercase name without the
prefix and the integer is the constant value.  For the full list see
L<Archive::Libarchive::API/CONSTANTS>.

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

=item L<Archive::Libarchive::ArchiveRead>

This class is used for reading from archives.

=item L<Archive::Libarchive::ArchiveWrite>

This class is for creating new archives.

=item L<Archive::Libarchive::DiskRead>

This class is for reading L<Archive::Libarchive::Entry> objects from disk
so that they can be written to L<Archive::Libarchive::ArchiveWrite> objects.

=item L<Archive::Libarchive::DiskWrite>

This class is for writing L<Archive::Libarchive::Entry> objects to disk
that have been written from L<Archive::Libarchive::ArchiveRead> objects.

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
