##
## Apache::Mmap::Handle -- Uses Apache::Mmap to access a mmaped file
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
## $Id: Handle.pm,v 1.4 1997/11/25 04:15:37 fletch Exp $
##

package Apache::Mmap::Handle;

require 5.004;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK 
	    $AUTOLOAD $DEBUG);

use Carp qw(:DEFAULT);

use Apache::Mmap qw(mmap munmap);
require AutoLoader;
require Exporter;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw( TIEHANDLE );
@EXPORT_OK = qw( MAP_ANON MAP_ANONYMOUS MAP_FILE MAP_PRIVATE MAP_SHARED
		 PROT_EXEC PROT_NONE PROT_READ PROT_WRITE );

$VERSION = $Apache::Mmap::VERSION;

sub TIEHANDLE ($$;$);

1;

__END__

## TIEHANDLE -- Tie a HANDLE to a mmaped file
sub TIEHANDLE ($$;$) {
  ## UGLY!!! Throw away passed in class. Allows tie *FOO, 'Apache::Mmap', ...
  ## but (?possibly?) bad for inheritance.  Should be better way . . .
  shift;			
  my $class = 'Apache::Mmap::Handle';
  my $file = shift;
  my $opts = shift || 'r';

  my $retval = {};

  print STDERR "${class}::TIEHANDLE called with:\n", join( ', ', @_ ) 
    if $Apache::Mmap::DEBUG > 1;

  if( $opts =~ /w/ ) {
    warn "$class::TIEHANDLE: write not implemented yet.\n";
    return undef;
  }

  $retval->{ '_mapped' } = Apache::Mmap::mmap( $file, $opts );
  $retval->{ '_pos' } = 0;
  $retval->{ '_len' } = length( ${$retval->{'_mapped'}} );
#  $retval->{ '_val' } = ${$retval->{'_mapped'}} if $opts eq 'r';

  print STDERR "${class}::TIEHANDLE _mmaped: ", $retval->{'_mapped'}, "\n"
    if $Apache::Mmap::DEBUG > 1;

  return bless( \$retval, $class );
}

sub READ ($@) {
  my $self = shift;
  $self = ${$self};
  my($buf,$len,$offset) = @_;

  my $val = $self->{'_val'} || ${$self->{'_mapped'}};

  return undef
    if $self->{'_pos'} == $self->{'_len'};

  my $class = ref $self;
  return "${class}::READ: Not implemented\n";
}

sub READLINE ($) {
  my $self = shift;
  $self = ${$self}; 

  my $val = $self->{'_val'} || ${$self->{'_mapped'}};

  ## If _pos is equal to _len we're at end of file, so return undef
  return undef 
    if $self->{'_pos'} == $self->{'_len'};	     

  my $index = index( $val, "\n", $self->{'_pos'} );
  my $len = ( $index != -1 ) ? $index - $self->{'_pos'} + 1
                             : $self->{'_len'} - $self->{'_pos'};

  my $ret = substr( $val, $self->{'_pos'}, $len );

  $self->{'_pos'} += $len + 1;

  return $ret;
}

sub DESTROY {
  my $self = shift;
  $self = ${$self};

  print STDERR "Apache::Mmap::DESTROY called\n"
    if $Apache::Mmap::DEBUG > 1;
}

=head1 NAME

Apache::Mmap::Handle - Associates a file handle with a mmaped file

=head1 SYNOPSIS

  use Apache::Mmap::Handle ();

  tie *MMAP, 'Apache::Mmap::Handle', $filename, 'r';
  print while( <MMAP> );
  untie *MMAP;

=head1 DESCRIPTION

C<Apache::Mmap::Handler> implements the C<TIEHANDLE> interface to allow
tieing a filehandle to a file which has been mapped into memory using
the C<Apache::Mmap> module.

=head1 AUTHOR

Mike Fletcher, lemur1@mindspring.com

=head1 SEE ALSO

Apache::Mmap module, mmap(2), perltie(1), perl(1).

=cut
