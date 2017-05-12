##
## Apache::Mmap -- Uses mmap(2) to map a file as a perl scalar.
##
## Copyright (c) 1997
## Mike Fletcher <lemur1@mindspring.com>
## 08/28/97
##
## THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED 
## WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
## OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
##
## See the files 'Copying' or 'Artistic' for conditions of use.
##

##
## $Id: Mmap.pm,v 1.6 1997/11/25 04:15:39 fletch Exp $
##

package Apache::Mmap;

require 5.004;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK 
	    $AUTOLOAD $DEBUG);

use Carp qw(:DEFAULT);
use Symbol qw(:DEFAULT);

##use Mmap qw(:DEFAULT);
use FileHandle qw(:DEFAULT);

require AutoLoader;
require DynaLoader;
require Exporter;

sub mmap ($;$);
sub unmap ($);

@ISA = qw(Exporter DynaLoader AutoLoader);
@EXPORT = qw( );
@EXPORT_OK = qw(mmap munmap
		MAP_ANON MAP_ANONYMOUS MAP_FILE MAP_PRIVATE MAP_SHARED
		PROT_EXEC PROT_NONE PROT_READ PROT_WRITE);

$VERSION = '0.05';
$Apache::Mmap::DEBUG = 0;

## Evil magic per DOUGM: Allows tie *FOO, 'Apache::Mmap', ... to work
## and still get to the correct destructors, etc.
eval {
  use Apache::Mmap::Handle qw( TIEHANDLE );
  *Apache::Mmap::TIEHANDLE = \&Apache::Mmap::Handle::TIEHANDLE;
};

my %_Mapped;			# Hash of mapped scalars

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Mmap macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

## mmap -- Calls Apache::Mmap::_do_map to tie the file given as the first arg
##        to mapped memory if needed, otherwise returns a cached reference
sub mmap ($;$) {
  my $file = shift;
  my $opts = shift || 'r';

  carp "'$file' already mapped, returning cache\n"
    if exists( $_Mapped{$file} ) and $Apache::Mmap::DEBUG > 4;

  my $retval = exists( $_Mapped{$file} ) 
    ? ${$_Mapped{$file}} : _do_map( $file, $opts );
}

## unmap -- Un-mmaps a file from memory.
sub munmap ($) {
  my $file = shift;

  ## Carp and return unless the file is actually mapped by us
  unless( $file and defined( $_Mapped{ $file } ) ){
    carp "Warning: File '$file' is not currently mapped by Apache::Mmap.\n";
    return undef;
  }

  carp "Unmapping '$file' and deleting from cache.\n"
    if $Apache::Mmap::DEBUG > 1;

  untie( ${$_Mapped{ $file }} ); # Call Mmap::unmap with the scalar

  delete $_Mapped{ $file };	# Remove the key from our cache hash

  return 1;	    
}

sub _do_map ($$) {
  my $file = shift;
  my $opts = shift;

  my $handle = gensym;
  my $scalar = gensym;

  $_Mapped{$file} = $scalar;

  my $mode = O_RDONLY;
  if( $opts eq 'w' ) {
    $mode = O_WRONLY;
  } elsif( $opts eq 'rw' ) {
    $mode = O_RDWR;
  }
  
  carp "\$mode: $mode\n" if $Apache::Mmap::DEBUG > 4;

  sysopen( $handle, $file, $mode )
    or croak "Can't open '$file': $!";

  $mode = PROT_READ();
  if( $opts eq 'w' ) {
    $mode = PROT_WRITE()
  } elsif( $opts eq 'rw' ) {
    $mode = PROT_READ()|PROT_WRITE();
  }

  carp "\$mode: $mode\n" if $Apache::Mmap::DEBUG > 4;

  tie $$$scalar, 'Apache::Mmap', $handle, 0, $mode, MAP_SHARED()
    or croak "Error on mmap: $!";

## Old stuf from Mmap
#  mmap( $$scalar, 0, $mode, MAP_SHARED, $handle )
#    or croak "Error on mmap: $!"; 

  close $handle;

  carp "Mapped '$file'\n"
    if $Apache::Mmap::DEBUG > 1;

  return $$scalar;
}

bootstrap Apache::Mmap $VERSION;

1;
__END__
	  
## handler -- mod_perl request handler
sub handler {
  use Apache::Constants qw(OK);

  my $r = shift;

  $r->log_error( "Apache::Mmap handling '" . $r->filename . "'\n" );

  $r->send_http_header();
  $r->print( ${Apache::Mmap::mmap( $r->filename() )} );

  return OK;
}

=head1 NAME

Apache::Mmap - Associates a scalar with a mmap'd file

=head1 SYNOPSIS

  use Apache::Mmap qw(mmap munmap);

  $mappedfile = mmap 'example.html';
  print $$mappedfile;
  munmap 'example.html';

  open( FILE, "jrandomfile" ) or die "Can't open file: $!";
  tie $scalar, 'Apache::Mmap', 
      *FILE, 0, Apache::Mmap::PROT_READ, Apache::Mmap::MAP_SHARED;
  print "jrandomfile contents:\n$scalar\n";
  untie $scalar;  

=head1 DESCRIPTION

C<Apache::Mmap> provides a facility for using the C<mmap(2)> system call to 
have the OS map a file into a process' address space.

Two interfaces are provided:

=over 4

=item *

C<mmap> and C<munmap> methods which provide a persistant caching mechanisim
similar to that provided by C<Apache::DBI> for database handles.

=item *

A set of methods which implement the C<TIESCALAR> interface allowing a
scalar variable to be tied to a mapped region of memory.  Reading or
writing to the tied scalar accesses the mapped buffer.

=back

=head1 Simple Interface

The simple interface provides two functions, C<mmap> and C<munmap>, to
manipulate a mapped area.  The mapped area is accessed using the scalar
reference returned by C<mmap>.

=head2 C<mmap>

The C<mmap> function takes the name of a file to map into memory as
its argument.  An optional second argument may be given to specify
what protections should be set on the mapped region.  This argument
should be one of B<"r"> (the default), B<"w">, or B<"rw">.  If the
file is successfully mapped a reference to a scalar will be returned.
Remember that you need to prepend an C<$> to dereference the scalar
and get the contents:

    $mapped = mmap '/tmp/foo', "rw";
    print "/tmp/foo:\n", $$mapped, "\n";
    $$mapped = "New contents\n";

The Apache::Mmap module keeps track of all of the files mapped using
the C<mmap> function.  If you call C<mmap> with a file which is alredy
mapped a reference to the already mapped scalar will be returned.

=head2 C<munmap>

Calling C<munmap> with a filename removes the association between
memory and existing mmapped file.  If C<munmap> is called with a
file which is not currently mapped, B<undef> will be returned.  If
the file is successfully unmapped B<1> will be returned.  Keep in
mind that you should be careful unmapping a file if you have multiple
copies of the reference returned by C<mmap>.

=head1 Tie Interface

I<To be written.  Look at how Apache::Mmap::mmap does it.>

=head1 Apache::Mmap::handler

A handler method is provided by the Apache::Mmap module suitable for
use under C<mod_perl> with B<Apache>.  To use the handler, add something
similar to the following to your C<access.conf> file:

   <Location /mmapped.html>
   SetHandler perl-script
   PerlHandler Apache::Mmap
   </Location>

replacing I</mmaped.html> as apropriate.  Your performance may vary.
See the benchmarking scripts in the C<eg> directory of the
distribution.

=head1 Warning Mapping with Offsets

Some platforms (Solaris for example) require files to be mapped on
memory page boundaries.  If you map with an offset, the offset must be
on a page boundary (e.g. with 4k pages, if you wanted to map with an
offset of 6k into the file, you would need to map starting at an
offset of 4k and look 2k in from the beginning of the mapped region
(I hope that made sense)).

A future version will provide access to the C<getpagesize()> system
call on platforms where it is available (SYSV and 4.4BSD).  You may
also look into the C<Sys::Sysconf> module which provides access to
C<_SC> macros from system header files for use with C<POSIX::sysconf>.
Some platforms (again, Solaris) provide an C<_SC_PAGESIZE> constant.

=head1 TODO

Keep track of the mode a file was mapped as for caching purposes.
Warn if a different mode is specified, or remap as requested?

Implement some sort of locking (flock, SysV semaphores, . . .) on
the mapped area.

Add support for the msync(2) and mlock(2) system calls.

Add support for madvise(2) on platforms supporting it.

Add hook to getpagesize(2) for platforms which require mappings at
offsets to be on page boundaries.

Add some way of specifying if the file's size should be truncated
to the length of the last scalar inserted on unmapping.  Likewise
figure out a good way to extend the file/mapped region if needed.

Look into using the Storable module for sharing hashes and arrays
(like IPC::Shareable module does for shm).

Make sure things work on more architectures/os's than Sparc/Solaris
2.5.1 and i586/Linux 2.0.30.

=head1 AUTHOR

Mike Fletcher, lemur1@mindspring.com

This module is based on (and incorporates some code from) Malcolm
Beattie's I<Mmap-alpha2> module.

=head1 SEE ALSO

mmap(2), perltie(1), perl(1), Malcolm Beattie's I<Mmap> module.

=cut
