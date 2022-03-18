package Archive::Libarchive::ArchiveRead;

use strict;
use warnings;
use 5.020;
use Archive::Libarchive::Lib;
use FFI::Platypus::Buffer qw( scalar_to_buffer scalar_to_pointer grow set_used_length window );
use FFI::Platypus::Memory qw( strdup free );
use Ref::Util qw( is_plain_scalarref is_plain_coderef is_blessed_ref is_plain_arrayref );
use Carp ();
use experimental qw( signatures );
use parent qw( Archive::Libarchive::Archive );
use constant;

# ABSTRACT: Libarchive read archive class
our $VERSION = '0.05'; # VERSION

my $ffi = Archive::Libarchive::Lib->ffi;
constant->import(_opaque_size => $ffi->sizeof('opaque'));


$ffi->mangler(sub ($name) { "archive_read_$name"  });

$ffi->attach( new => [] => 'opaque' => sub {
  my($xsub, $class) = @_;
  my $ptr = $xsub->();
  bless { ptr => $ptr }, $class;
});

$ffi->attach( [ free => 'DESTROY' ] => ['archive_read'] => 'int' => sub {
  my($xsub, $self) = @_;
  free delete $self->{passphrase} if defined $self->{passphrase};
  return if $self->{cb}                 # inside a callback, we don't own the archive pointer
    || ${^GLOBAL_PHASE} eq 'DESTRUCT';  # during global shutdown the xsub might go away
  my $ret = $xsub->($self);
  warn "destroying archive pointer did not return ARCHIVE_OK" unless $ret == 0;
});


my %set_callback = map {
  ($_ => $ffi->function( "set_${_}_callback" => ['archive_read',"archive_${_}_callback"] => 'int' )->sub_ref)
} qw( open close read seek skip );

$ffi->attach( [ set_callback_data => '_set_callback_data' ] => ['archive_read','opaque'] => 'int' );

$ffi->attach( [ open1 => 'open' ] => [ 'archive_read'] => 'int' => sub {
  my($xsub, $self, %callbacks) = @_;

  Carp::croak("The read callback is required") unless $callbacks{read};

  foreach my $name (keys %set_callback)
  {
    my $set = $set_callback{$name};
    my $sub = delete $callbacks{$name};

    unless(defined $sub)
    {
      $set->($self, undef);
      next;
    }

    Carp::croak("Callback for $name is not a code reference") unless is_plain_coderef $sub;

    my $closure;

    if($name eq 'read')
    {
      $closure = FFI::Platypus->closure(sub ($r, $, $ptrptr) {
        $r = bless { ptr => $r, cb => 1 }, __PACKAGE__;
        $self->{read_buffer} = undef;
        my $size = $sub->($r, \$self->{read_buffer});
        my $ptr = defined $self->{read_buffer} ? scalar_to_pointer($self->{read_buffer}) : undef;
        _memcpy($ptrptr, [$ptr], _opaque_size());
        return $size;
      });
    }
    else
    {
      $closure = FFI::Platypus->closure(sub ($r, $, @therest) {
        $r = bless { ptr => $r, cb => 1 }, __PACKAGE__;
        $sub->($r, @therest);
      });
    }

    push @{ $self->{keep} }, $closure;

    $set->($self, $closure);
  }

  Carp::croak("No such read callbacks: @{[ sort keys %callbacks ]}") if %callbacks;

  _set_callback_data($self, undef);

  $xsub->($self);
});


$ffi->attach( open_memory => ['archive_read','opaque','size_t'] => 'int' => sub {
  my($xsub, $self, $ref) = @_;
  Carp::croak("buffer must be a scalar reference")
    unless defined $ref && is_plain_scalarref $ref;
  push @{ $self->{keep} }, \($$ref);
  my($ptr, $size) = scalar_to_buffer $$ref;
  $xsub->($self, $ptr, $size);
});


$ffi->attach( open_FILE => ['archive_read', 'opaque'] => 'int' => sub {
  my($xsub, $self, $fp) = @_;
  $fp = $$fp if is_blessed_ref $fp && $fp->isa('FFI::C::File');
  $xsub->($self, $fp);
});


sub open_perlfile ($self, $fh)
{
  $self->open(
    read => sub ($r, $ref) {
      return sysread $fh, $$ref, 512;
    },
    close => sub ($r) {
      close $fh;
    },
  );
}


$ffi->attach( open_filenames => ['archive_read', 'string[]', 'size_t'] => 'int' => sub {
  my($xsub, $self, $filenames, $size) = @_;
  Carp::croak("Filenames must be provided as an array reference")
    unless defined $filenames && is_plain_arrayref $filenames;
  $xsub->($self, defined $filenames->[-1] ? [@$filenames, undef] : $filenames, $size);
});


$ffi->attach( [ next_header2 => 'next_header' ] => ['archive_read','archive_entry'] => 'int' => sub {
  my($xsub, $self, $entry) = @_;
  $xsub->($self, $entry);
});


$ffi->attach( [data => 'read_data'] => ['archive_read', 'opaque', 'size_t'] => 'ssize_t' => sub {
  my($xsub, $self, $ref, $size) = @_;
  $size ||= 512;

  grow $$ref, $size, { clear => 0 };
  my $rsize = $xsub->($self, (scalar_to_buffer $$ref));
  set_used_length $$ref, $rsize;

  return $rsize;
});


$ffi->attach( [data_block => 'read_data_block' ] => ['archive_read', 'opaque*', 'size_t*', 'sint64*'] => 'int' => sub {
  my $xsub = shift;
  my($ptr, $size);
  my $ret = $xsub->($_[0], \$ptr, \$size, $_[2]);
  window ${$_[1]}, $ptr, $size if defined $ptr;
  return $ret;
});


$ffi->attach( append_filter => ['archive_read', 'archive_filter_t'] => 'int' );
$ffi->attach( set_format => ['archive_read', 'archive_format_t'] => 'int' );


$ffi->attach( set_passphrase_callback => ['archive_read', 'opaque', 'archive_passphrase_callback'] => 'int' => sub {
  my($xsub, $self, $sub) = @_;

  my $closure = FFI::Platypus->closure(sub ($r, $) {
    $r = bless { ptr => $r, cb => 1 }, __PACKAGE__;
    my $passphrase = $sub->($r);
    $passphrase = '' unless defined $passphrase;
    my $ptr = strdup $passphrase;
    free delete $self->{passphrase} if defined $self->{passphrase};
    return $self->{passphrase} = $ptr;
  });

  push @{ $self->{keep} }, $closure;

  $xsub->($self, undef, $closure);

});

require Archive::Libarchive::Lib::ArchiveRead unless $Archive::Libarchive::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::ArchiveRead - Libarchive read archive class

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use 5.020;
 use Archive::Libarchive qw( :const );
 
 my $r = Archive::Libarchive::ArchiveRead->new;
 $r->support_filter_all;
 $r->support_format_all;
 $r->open_filename("archive.tar", 10240) == ARCHIVE_OK
   or die $r->error_string;
 
 my $e = Archive::Libarchive::Entry->new;
 say $e->pathname while $r->next_header($e) == ARCHIVE_OK;

=head1 DESCRIPTION

This class represents an archive instance for reading from archives.

=head1 CONSTRUCTOR

=head2 new

 # archive_read_new
 my $r = Archive::Libarchive::ArchiveRead->new;

Create a new archive read object.

=head1 METHODS

This is a subset of total list of methods available to all archive classes.
For the full list see L<Archive::Libarchive::API/Archive::Libarchive::ArchiveRead>.

=head2 open

 # archive_read_open1
 # archive_read_set_callback_data
 # archive_read_set_close_callback
 # archive_read_set_open_callback
 # archive_read_set_read_callback
 # archive_read_set_seek_callback
 # archive_read_set_skip_callback
 $r->open(%callbacks);

This is a basic open method, which relies on callbacks for its implementation.  The
only callback that is required is the C<read> callback.  The C<open> and C<close>
callbacks are made available mostly for the benefit of the caller.  The C<skip>
and C<seek> callbacks are used if available for some formats like C<zip> to improve
performance.  All callbacks should return a L<normal status code|Archive::Libarchive/CONSTANTS>,
which is C<ARCHIVE_OK> on success.

Unlike the C<libarchive> C-API, this interface doesn't provide a facility for
passing in "client" data.  In Perl this is implemented using a closure, which should
allow you to pass in arbitrary variables via proper scoping.

=over 4

=item open

 $r->open(open => sub ($r) {
   ...
 });

Called immediately when the archive is "opened";

=item read

 $r->open(read => sub ($r, $ref) {
   $$ref = ...;
   ...
   return $size.
 });

Called when new data is required.  What is passed in is a scalar reference.  You should
set this scalar to the next block of data.  On success you should return the size of
the data in bytes, and on failure return a L<normal status code|Archive::Libarchive/CONSTANTS>.

=item seek

 $r->open(seek => sub ($r, $offset, $whence) {
   ...
 });

Called to seek to the new location.  The C<$offset> and C<$whence> arguments work exactly
like the C<libc> C<fseek> function.

=item skip

 $r->open(skip => sub ($r, $request) {
   ...
 });

Called to skip the next C<$request> bytes.  Should return the actual number of bytes skipped
on success (which can be less than or equal to C<$request>), and on failure return a
L<normal status code|Archive::Libarchive/CONSTANTS>.

=item close

 $r->open(close => sub ($r) {
   ...
 });

This is called when the archive instance is closed.

=back

=head2 open_memory

 # archive_write_open_memory
 my $code = $r->open_memory(\$buffer);

Open's the in-memory archive.

=head2 open_FILE

 $r->open_FILE($file_pointer);

This takes either a L<FFI::C::File>, or an opaque pointer to a libc file pointer.

=head2 open_perlfile

 $r->open_perlfile(*FILE);

This takes a perl file handle and reads the archive from there.

=head2 open_filenames

 # archive_read_open_filenames
 my $int = $r->open_filenames(\@filenames, $size_t);

Open a multi-file archive (typically for RAR format).   The C<$size_t> argument is
the block size.

=head2 next_header

 # archive_read_next_header
 my $code = $r->next_header($e);

Returns the next L<Archive::Libarchive::Entry> object.

=head2 read_data

 # archive_read_data
 my $size_or_code = $r->read_data(\$buffer, $size);
 my $size_or_code = $r->read_data(\$buffer);

Read in data from the content section of the archive entry.  The output is written into
C<$buffer>.  Up to C<$size> bytes will be read.  This will return the number of bytes
read on success, zero (C<0>) on EOF and a L<normal status code|Archive::Libarchive/CONSTANTS>
on error.

=head2 read_data_block

 # archive_read_data_block
 my $int = $r->read_data_block(\$buffer, \$offset);

A zero-copy version of archive_read_data that also exposes the file offset
of each returned block.  Note that the client has no way to specify
the desired size of the block.  The API does guarantee that offsets will
be strictly increasing and that returned blocks will not overlap.

Gotcha with this method is that it returns C<ARCHIVE_EOF> when there is no
more data to read instead of the number of bytes.  The size can be determined
from the length of the newly resized C<$buffer>.

=head2 append_filter

 # archive_read_append_filter
 my $int = $r->append_filter($code);

Append filter to manually specify the order in which filters will be
applied.  This will accept either a string representation of the filter
code, or the constant.  The constant prefix is C<ARCHIVE_FILTER_>.  So
for a gzipped file this would be either C<'gzip'> or C<ARCHIVE_FILTER_GZIP>.
For the full list see L<Archive::Libarchive::API/CONSTANTS>.

=head2 set_format

 # archive_read_set_format
 my $int = $r->set_format($code);

Set the format manually.  This will accept either a string representation
of the format, or the constant.  The constant prefix is C<ARCHIVE_FORMAT_>.
So for a tar file this would be either C<'tar'> or C<ARCHIVE_FORMAT_TAR>.

=head2 set_passphrase_callback

 # archive_read_set_passphrase_callback
 my $int = $r->set_passphrase_callback(sub ($r) {
   ...
   return $passphrase;
 });

Set a callback that will be called when a passphrase is required, for example with a .zip
file with encrypted entries.

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
