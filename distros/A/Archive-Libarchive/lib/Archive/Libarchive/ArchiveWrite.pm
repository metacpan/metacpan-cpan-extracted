package Archive::Libarchive::ArchiveWrite;

use strict;
use warnings;
use 5.020;
use Archive::Libarchive::Lib;
use Carp ();
use Ref::Util qw( is_plain_coderef is_blessed_ref );
use FFI::Platypus::Buffer qw( window scalar_to_buffer );
use FFI::Platypus::Memory qw( strdup free );
use experimental qw( signatures );
use parent qw( Archive::Libarchive::Archive );

# ABSTRACT: Libarchive write archive class
our $VERSION = '0.05'; # VERSION

my $ffi = Archive::Libarchive::Lib->ffi;


$ffi->mangler(sub ($name) { "archive_write_$name"  });

$ffi->attach( new => [] => 'opaque' => sub {
  my($xsub, $class) = @_;
  my $ptr = $xsub->();
  bless { ptr => $ptr }, $class;
});

$ffi->attach( [ free => 'DESTROY' ] => ['archive_write'] => 'int' => sub {
  my($xsub, $self) = @_;
  free delete $self->{passphrase} if defined $self->{passphrase};
  return if $self->{cb}                  # inside a callback, we don't own the archive pointer
    || ${^GLOBAL_PHASE} eq 'DESTRUCT';   # during global shutdown, the xsub might go away
  my $ret = $xsub->($self);
  warn "destroying archive pointer did not return ARCHIVE_OK" unless $ret == 0;
});


$ffi->attach( open => ['archive_write', 'opaque', 'archive_open_callback', 'archive_write_callback', 'archive_close_callback'] => 'int' => sub {
  my($xsub, $self, %cb) = @_;

  foreach my $name (qw( open write close ))
  {
    if(defined $cb{$name} && !is_plain_coderef $cb{$name})
    {
      Carp::croak("The $name callback is not a subref");
    }
  }

  my $opener = delete $cb{open};
  my $writer = delete $cb{write};
  my $closer = delete $cb{close};

  Carp::croak("Write callback is required") unless $writer;
  Carp::croak("No such write callbacks: @{[ sort keys %cb ]}") if %cb;

  if($opener)
  {
    my $orig = $opener;
    $opener = FFI::Platypus->closure(sub ($w, $) {
      $w = bless { ptr => $w, cb => 1 }, __PACKAGE__;
      $orig->($w);
    });
    push @{ $self->{keep} }, $opener;
  }

  if($writer)
  {
    my $orig = $writer;
    $writer = FFI::Platypus->closure(sub ($w, $, $ptr, $size) {
      $w = bless { ptr => $w, cb => 1 }, __PACKAGE__;
      my $buffer;
      window $buffer, $ptr, $size;
      $orig->($w, \$buffer);
    });
    push @{ $self->{keep} }, $writer;
  }

  if($closer)
  {
    my $orig = $closer;
    $closer = FFI::Platypus->closure(sub ($w, $) {
      $w = bless { ptr => $w, cb => 1 }, __PACKAGE__;
      $orig->($w);
    });
    push @{ $self->{keep} }, $closer;
  }

  $xsub->($self, undef, $opener, $writer, $closer);
});


$ffi->attach( open_FILE => ['archive_write', 'opaque'] => 'int' => sub {
  my($xsub, $self, $fp) = @_;
  $fp = $$fp if is_blessed_ref $fp && $fp->isa('FFI::C::File');
  $xsub->($self, $fp);
});


sub open_memory ($self, $image)
{
  # TODO: it would be nice to pre-allocate $$ref with grow (FFI::Platypus::Buffer)
  # but that gave me scary errors, so look into it later.
  $self->open(
    write => sub ($w, $ref) {
      $$image .= $$ref;
      return length $$ref;
    },
  );
}


sub open_perlfile ($self, $fh)
{
  $self->open(
    write => sub ($w, $ref) {
      return syswrite $fh, $$ref;
    },
    close => sub ($w) {
      close $fh;
    },
  );
}


$ffi->attach( [ data => 'write_data' ] => ['archive_write', 'opaque', 'size_t'] => 'ssize_t' => sub {
  my $xsub = shift;
  my $self = shift;
  $xsub->($self, scalar_to_buffer ${$_[0]});
});


$ffi->attach( add_filter => ['archive_write', 'archive_filter_t'] => 'int' );
$ffi->attach( set_format => ['archive_write', 'archive_format_t'] => 'int' );


$ffi->attach( set_passphrase_callback => ['archive_write', 'opaque', 'archive_passphrase_callback'] => 'int' => sub {
  my($xsub, $self, $sub) = @_;

  my $closure = FFI::Platypus->closure(sub ($w, $) {
    $w = bless { ptr => $w, cb => 1 }, __PACKAGE__;
    my $passphrase = $sub->($w);
    $passphrase = '' unless defined $passphrase;
    my $ptr = strdup $passphrase;
    free delete $self->{passphrase} if defined $self->{passphrase};
    return $self->{passphrase} = $ptr;
  });

  push @{ $self->{keep} }, $closure;

  $xsub->($self, undef, $closure);

});



require Archive::Libarchive::Lib::ArchiveWrite unless $Archive::Libarchive::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Libarchive::ArchiveWrite - Libarchive write archive class

=head1 VERSION

version 0.05

=head1 SYNOPSIS

 use 5.020;
 use Archive::Libarchive;
 use Path::Tiny qw( path );
 
 my $w = Archive::Libarchive::ArchiveWrite->new;
 $w->set_format_pax_restricted;
 $w->open_filename("outarchive.tar");
 
 path('.')->visit(sub ($path, $) {
   my $path = shift;
 
   return if $path->is_dir;
 
   my $e = Archive::Libarchive::Entry->new;
   $e->set_pathname("$path");
   $e->set_size(-s $path);
   $e->set_filetype('reg');
   $e->set_perm( oct('0644') );
   $w->write_header($e);
   $w->write_data(\$path->slurp_raw);
 
 }, { recurse => 1 });
 
 $w->close;

=head1 DESCRIPTION

This class represents an archive instance for writing to archives.

=head1 CONSTRUCTOR

=head2 new

 # archive_write_new
 my $w = Archive::Libarchive::ArchiveWrite->new;

Create a new archive write object.

=head1 METHODS

This is a subset of total list of methods available to all archive classes.
For the full list see L<Archive::Libarchive::API/Archive::Libarchive::ArchiveRead>.

=head2 open

 # archive_write_open
 $w->open(%callbacks);

This is a basic open method, which relies on callbacks for its implementation.  The
only callback that is required is the C<write> callback.  The C<open> and C<close>
callbacks are made available mostly for the benefit of the caller.  All callbacks
should return a L<normal status code|Archive::Libarchive/CONSTANTS>, which is
C<ARCHIVE_OK> on success.

Unlike the C<libarchive> C-API, this interface doesn't provide a facility for
passing in "client" data.  In Perl this is implemented using a closure, which should
allow you to pass in arbitrary variables via proper scoping.

=over 4

=item open

 $w->open(open => sub ($w) {
   ...
 });

Called immediately when the archive is "opened";

=item write

 $w->open(write => sub ($w, $ref) {
   ... = $$ref;
   return $size;
 });

This callback is called when data needs to be written to the archive.  It is passed in
as a reference to a scalar that contains the raw data.  On success you should return the actual size of
the data written in bytes, and on failure return a L<normal status code|Archive::Libarchive/CONSTANTS>.

=item close

 $w->open(open => sub ($w) {
   ...
 });

This is called when the archive instance is closed.

=back

=head2 open_FILE

 # archive_write_open_FILE
 $w->open_FILE($file_pointer);

This takes either a L<FFI::C::File>, or an opaque pointer to a libc file pointer.

=head2 open_memory

 # archive_write_open_memory
 $w->open_memory(\$buffer);

This takes a reference to scalar and stores the archive in memory there.

=head2 open_perlfile

 $w->open_perlfile(*FILE);

This takes a perl file handle and stores the archive there.

=head2 write_data

 # archive_write_data
 my $size_or_code = $w->write_data(\$buffer);

Write the entry content data to the archive.  This takes a reference to the buffer.
Returns the number of bytes written on success, and a L<normal status code|Archive::Libarchive/CONSTANTS>
on error.

=head2 add_filter

 # archive_write_add_filter
 my $int = $w->add_filter($code);

Add filter to be applied when writing the archive.
This will accept either a string representation of the filter
code, or the constant.  The constant prefix is C<ARCHIVE_FILTER_>.  So
for a gzipped file this would be either C<'gzip'> or C<ARCHIVE_FILTER_GZIP>.
For the full list see L<Archive::Libarchive::API/CONSTANTS>.

=head2 set_format

 # archive_write_set_format
 my $int = $w->set_format($code);

Set the output format.  This will accept either a string representation
of the format, or the constant.  The constant prefix is C<ARCHIVE_FORMAT_>.
So for a tar file this would be either C<'tar'> or C<ARCHIVE_FORMAT_TAR>.

=head2 set_passphrase_callback

 # archive_write_set_passphrase_callback
 my $int = $w->set_passphrase_callback(sub ($w) {
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

=item L<Archive::Libarchive::ArchiveRead>

This class is used for reading from archives.

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
