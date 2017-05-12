package Archive::Ar::Libarchive;

use strict;
use warnings;
use base qw( Exporter );
use constant COMMON => 1;
use constant BSD    => 2;
use constant GNU    => 3;
use Carp qw( carp longmess );
use File::Basename ();

# ABSTRACT: Interface for manipulating ar archives with libarchive
our $VERSION = '2.06'; # VERSION

unless($^O eq 'MSWin32')
{
  require Alien::Libarchive;
  Alien::Libarchive->import;
}

require XSLoader;
XSLoader::load('Archive::Ar::Libarchive', $VERSION);

our @EXPORT_OK = qw( COMMON BSD GNU );


sub new
{
  my($class, $filename_or_handle, $debug) = @_;
  my $self = _new();
  $self->DEBUG if $debug;
  
  if($filename_or_handle)
  {
    unless($self->read($filename_or_handle))
    {
      return $self->_error("new() failed on filename for filehandle read");
    }
  }
  
  $self;
}


sub read
{
  my($self, $filename_or_handle) = @_;

  my $ret = 0;
  
  if(ref $filename_or_handle)
  {
    return $self->_error("Not a filehandle") unless eval{*$filename_or_handle{IO}} or $filename_or_handle->isa('IO::Handle');
    my $buffer;
    $ret = $self->_read_from_callback(sub {
      my $br = read $filename_or_handle, $buffer, 1024;
      ((defined $br ? 0 : -30), \$buffer);
    });
    close $filename_or_handle;
  }
  else
  {
    $ret = $self->_read_from_filename($filename_or_handle);
  }

  $ret || undef;
}


sub read_memory
{
  my($self, $data) = @_;
  
  open my $fh, '<', \$data;
  binmode $fh;
  my $ret = $self->read($fh);
  
  $ret;
}


sub chmod
{
  my($self, $filename, $mode) = @_;
  $self->_chmod($filename, $mode + 0 eq $mode ? $mode : oct($mode));
}


sub chown
{
  my($self, $filename, $uid, $gid) = @_;
  $self->_chown($filename, $uid, $gid);
}


sub remove
{
  my $self = shift;
  my $count = 0;
  foreach my $pathname (@{ ref $_[0] ? $_[0] : \@_ })
  {
    $count += $self->_remove($pathname);
  }
  $count;
}


sub list_files
{
  my $list = shift->_list_files;
  wantarray ? @$list : $list;
}


sub add_files
{
  my $self = shift;
  my $count = 0;
  foreach my $filename (@{ ref $_[0] ? $_[0] : \@_ })
  {
    unless(-r $filename)
    {
      $self->_error("No such file: $filename");
      next;
    }
    my @props = stat($filename);
    unless(@props)
    {
      $self->_error("Could not stat $filename.");
      next;
    }
    
    open(my $fh, '<', $filename) || do {
      $self->_error("Unable to open $filename $!");
      next;
    };
    binmode $fh;
    # TODO: we don't check for error on the actual
    # read operation (but then nethier does
    # Archive::Ar).
    my $data = do { local $/; <$fh> };
    close $fh;
    
    $self->add_data(File::Basename::basename($filename), $data, {
      date => $props[9],
      uid  => $props[4],
      gid  => $props[5],
      mode => $props[2],
      size => length $data,
    });
    $count++;
  }
  
  return unless $count;
  $count;
}


sub add_data
{
  my($self, $filename, $data, $filedata) = @_;
  $filedata ||= {};
  $self->_add_data($filename, $data, $filedata->{uid} || 0, $filedata->{gid} || 0, $filedata->{date} || time, $filedata->{mode} || 0100644);
  use bytes;
  length $data;
}


sub write
{
  my($self, $filename) = @_;
  if(defined $filename)
  {
    my $fh;
  
    if(ref $filename)
    {
      return $self->_error("Not a filehandle") unless eval{*$filename{IO}} or $filename->isa('IO::Handle');
      $fh = $filename;
      
      return $self->_write_to_callback(sub {
        my($archive, $buffer) = @_;
        print $fh $buffer;
        length $buffer;
      });
    }

    return $self->_write_to_filename($filename);
  }
  else
  {
    my $content = '';
    my $status = $self->_write_to_callback(sub {
      my($archive, $buffer) = @_;
      $content .= $buffer;
      length $buffer;
    });
    return unless $status;
    return $content;
  }
}


sub get_handle
{
  my $data = shift->get_data(@_);
  return unless defined $data;
  open my $fh, '<', \$data;
  $fh;
}


sub set_output_format_bsd
{
  carp "set_output_format_bsd is deprecated, use \$ar->set_opt(type => BSD) instead";
  shift->set_opt(type => BSD);
}

sub set_output_format_svr4
{
  carp "set_output_format_bsd is deprecated, use \$ar->set_opt(type => COMMON) instead";
  shift->set_opt(type => COMMON);
}

sub DEBUG
{
  carp "DEBUG is deprecated, use \$ar->set_opt(\"warn\", 1) instead";
  my($self, $value) = @_;
  $self->set_opt(warn => 1) unless defined $value and $value == 0;
}

sub _error
{
  my($self, $message) = @_;
  my $opt_warn = $self->get_opt('warn');
  my $longmess = longmess $message;
  $self->_set_error($message, $longmess);
  if($opt_warn > 1)
  {
    carp $longmess;
  }
  elsif($opt_warn)
  {
    carp $message;
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::Ar::Libarchive - Interface for manipulating ar archives with libarchive

=head1 VERSION

version 2.06

=head1 SYNOPSIS

 use Archive::Ar::Libarchive;
 
 my $ar = Archive::Ar->new('libfoo.a');
 
 $ar->add_data('newfile.txt', 'some contents', { uid => 101, gid => 102 });
 
 $ar->add_files('./bar.tar.gz', 'bat.pl');
  
 $ar->remove('file1', 'file2');
 
 my $content = $ar->get_content('file3')->{data};
 
 my @files = $ar->list_files;
 
 $ar->write('libbar.a');
 
 my @file_list = $ar->list_files;

=head1 DESCRIPTION

This module is a XS alternative to L<Archive::Ar> that uses libarchive 
to read and write ar BSD, GNU and common ar archives.

There is no standard for the ar format.  Most modern archives are based 
on a common format with two extension variants, BSD and GNU.  Other 
esoteric variants (such as AIX (small), AIX (big) and Coherent) vary 
significantly from the common format and are not supported.  Debian's 
package format (.deb files) use the common format.

The interface attempts to be identical (with a couple of minor 
extensions) to L<Archive::Ar> and the documentation presented here is 
based on that module. The diagnostic messages issued on error mostly 
come directly from libarchive, so they will likely not match exactly 
what L<Archive::Ar> would produce, but it should issue a warning under
similar  circumstances.

The main advantage of L<Archive::Ar> over this module is that it is 
written in pure perl, and thus does not require a compiler or 
libarchive.  As an XS module using libarchive it may be faster.

You may notice that the API to L<Archive::Ar::Libarchive> and
L<Archive::Ar> is similar to L<Archive::Tar> and this was done
intentionally to keep similarity between the Archive::* modules.

=head1 METHODS

=head2 new

 my $ar = Archive::Ar::Libarchive->new;
 my $ar = Archive::Ar::Libarchive->new($filename);
 my $ar = Archive::Ar::Libarchive->new($fh);

Returns a new L<Archive::Ar::Libarchive> object.  Without a filename or 
glob, it returns an empty object.  If passed a filename as a scalar or a 
GLOB, it will attempt to populate from either of those sources.  If it 
fails, you will receive C<undef>, instead of an object reference.

=head2 set_opt

 $ar->set_opt($name, $value);

Assign option C<$name> value C<$value>.  Supported options include:

=over 4

=item warn

Warning level.  Levels are zero for no warnings, 1 for brief warnings,
and 2 for warnings with a stack trace.  Default is zero.

Warnings that originate with libarchive itself will not include a
stacktrace, even with a warn level set to 2.

=item chmod

Change the file permissions of files created when extracting.  Default
is true (non-zero).

This option is provided only for compatibility with L<Archive::Ar>.
Libarchive does not provide an equivalent to this option, so setting
it to false will has no effect.

=item same_perms

When setting file permissions, use the values in the archive unchanged.
If false, removes setuid bits and applies the user's umask.  Default
is true.

In L<Archive::Ar> this option is true for root only.

=item chown

Change the owners of extracted files, if possible.  Default is true.

=item type

Archive type.  May be GNU, BSD or COMMON, or undef if no archive
has been read.  Defaults to the type of the archive read or C<undef>.

=item symbols

Provide a filename for the symbol table, if present.  If set, the
symbol table is treated as a file that can be read from or written
to an archive.  It is an error if the filename provided matches the
name of a file in the archive.  If C<undef>, the symbol table is
ignored.  Defaults to C<undef>.

=back

=head2 get_opt

 my $value = $ar->get_opt($name);

Returns the value of the option C<$name>.

=head2 type

 my $type = $ar->type;

Returns the type of the ar archive.  The type is undefined until an archive
is loaded.  If the archive displays characteristics of a GNU-style archive,
GNU is returned.  If it looks like a bsd-style archive, BSD is returned.
Otherwise, COMMON is returned.  Note that unless filenames exceed 16
characters in length, bsd archives look like the common format.

=head2 clear

 $ar->clear;

Clears the current in-memory archive.

=head2 read

 my $br = $ar->read($filename);
 my $br = $ar->read($fh);

This reads a new file into the object, removing any ar archive already
represented in the object.  The argument may be either a filename,
filehandle or IO::Handle object.  Returns the number of bytes read,
C<undef> on failure.

=head2 read_memory

 my $br = $ar->read_memory($data);

This reads information from the first parameter, and attempts to parse 
and treat it like an ar archive. Like L<Archive::Ar::Libarchive#read>, 
it will wipe out whatever you have in the object and replace it with the 
contents of the new archive, even if it fails. Returns the number of 
bytes read (processed) if successful, C<undef> otherwise.

=head2 contains_file

 my $bool = $ar->contains_file($filename)

Returns true if the archive contains a file with the name C<$filename>.
Returns C<undef> otherwise.

=head2 extract

 $ar->extract;

Extract all files from the archive.  Extracted files are assigned the
permissions and modification time stored in the archive, and, if possible,
the user and group ownership.  Returns true on success, C<undef> for failure.

=head2 extract_file

 $ar->extract_file($filename);

Extracts a single file from the archive.  The extracted file is assigned
the permissions and modification time stored in the archive, and, if
possible, the user and group ownership.  Returns true on success,
C<undef> for failure.

=head2 rename

 $ar->rename($filename, $newname);

Changes the name of a file in the in-memory archive.

=head2 chmod

 $ar->chmod($filename, $mode);

Change the permission mode of the member to C<$mode>.

=head2 chown

 $ar->chown($filename, $uid, $gid);
 $ar->chown($filename, $uid);

Change the ownership of the member to user id C<$udi> and (optionally)
group id C<$gid>.  Negative id values are ignored.

=head2 remove

 my $count = $ar->remove(@pathnames);
 my $count = $ar->remove(\@pathnames);

The remove method takes a filenames as a list or as an arrayref, and removes
them, one at a time, from the Archive::Ar object.  This returns the number
of files successfully removed from the archive.

=head2 list_files

 my @list = $ar->list_files;
 my $list = $ar->list_files;

This lists the files contained inside of the archive by filename, as
an array. If called in a scalar context, returns a reference to an
array.

=head2 add_files

 $ar->add_files(@filenames);
 $ar->add_files(\@filenames);

Takes an array or an arrayref of filenames to add to the ar archive,
in order. The filenames can be paths to files, in which case the path
information is stripped off. Filenames longer than 16 characters are
truncated when written to disk in the format, so keep that in mind
when adding files.

Due to the nature of the ar archive format, 
L<Archive::Ar::Libarchive#add_files> will store the uid, gid, mode, 
size, and creation date of the file as returned by 
L<stat|perlfunc#stat>.

returns the number of files successfully added, or C<undef> on failure.

=head2 add_data

 my $size = $ar->add_data($filename, $data, $filedata);

Takes an filename and a set of data to represent it. Unlike 
L<Archive::Ar::Libarchive#add_files>, 
L<Archive::Ar::Libarchive#add_data> is a virtual add, and does not 
require data on disk to be present. The data is a hash that looks like:

 $filedata = {
   uid  => $uid,   #defaults to zero
   gid  => $gid,   #defaults to zero
   date => $date,  #date in epoch seconds. Defaults to now.
   mode => $mode,  #defaults to 0100644;
 };

You cannot add_data over another file however.  This returns the file 
length in bytes if it is successful, C<undef> otherwise.

=head2 write

 my $content = $ar->write;
 my $size = $ar->write($filename);

This method will return the data as an .ar archive, or will write to the 
filename present if specified. If given a filename, 
L<Archive::Ar::Libarchive#write> will return the length of the file 
written, in bytes, or C<undef> on failure. If the filename already exists, 
it will overwrite that file.

=head2 get_content

 my $hash = get_content($filename);

This returns a hash with the file content in it, including the data that the
file would naturally contain.  If the file does not exist or no filename is
given, this returns C<undef>. On success, a hash is returned with the following
keys:

=over 4

=item name

The file name

=item date

The file date (in epoch seconds)

=item uid

The uid of the file

=item gid

The gid of the file

=item mode

The mode permissions

=item size

The size (in bytes) of the file

=item data

The contained data

=back

=head2 get_data

 my $data = $ar->get_data($filename);

Returns a scalar containing the file data of the given archive member.
On error returns C<undef>.

=head2 get_handle

 my $handle = $ar->get_handle($filename);

Returns a file handle to the in-memory file data of the given archive
member.  On error returns C<undef>.  This can be useful for unpacking
nested archives.

=head2 error

 my $error_string = $ar->error($trace);

Returns the current error string, which is usually the last error
reported.  If a true value is provided, returns the error message
and stack trace.

=head1 SEE ALSO

=over 4

=item L<Alien::Libarchive>

=item L<Archive::Ar>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
