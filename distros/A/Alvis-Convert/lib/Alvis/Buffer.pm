# $Id: Buffer.pm,v 1.1 2006/12/01 09:40:24 buntine Exp $

package Alvis::Buffer;

use strict;
use warnings;
use Time::Simple;

use encoding 'utf8';
use open ':utf8';
binmode STDIN, ":utf8";
binmode STDERR, ":utf8";

our $VERSION = '0.10';

=head1 NAME

Alvis::Buffer - Perl extension for buffering utilities for the Alvis pipeline

=head1 SYNOPSIS

 use Alvis::Buffer;
 $Buffer::BUFFER = "/tmp/building.xml";
 $Buffer::verbose++;
 &Buffer::fix() or die "Cannot Buffer::fix";
 $in = new Alvis::Pipeline::Read(host => "harvester.alvis.info",
                                 port => 16716,
                                 spooldir => "/home/alvis/spool");
 while ($xml = $in->read(1)) {
     &clean_wrapping(\$xml);
     &Buffer::add($xml);
     if ( $Buffer::docs>1000 ) {
        $filename = &Buffer::save();
        if ( !$filename ) {
           &Buffer::close();
           die "Cannot Buffer::save";
        }
     }
 }
 $filename = &Buffer::save();
 &Buffer::close();

=head1 DESCRIPTION

This module provides a way of buffering Alvis XML into manageable chunks
as it is read in from a pipeline (Alvis::Pipeline).
Chunks can be controlled by file size or document count, but this is
done externally to the module, and the module simple provides a
function to save the current buffer contents.

Files of collected Alvis XML documents, with appropriate XML header
and footer parts, are saved in the relative directory "xml-add/"
under numbers 1,2,3, ...  At each time of storage, the current
directory is checked to see which number to use to store the latest
batch.   If "xml-add/" is empty, then "xml/" is checked instead.
Presumably, files in "xml-add/" are being processed into "xml/".

The implementation is independent of any pipeline,
and assumes a number of fixed directories.
Assumes files are in UTF-8, and that documents are present
in elements named <documentRecord>.

=head1 FUNCTIONS

=head2 fix()

 &Buffer::fix() or die "Cannot Buffer::fix";

Basic initialisation and checking to ensure the output buffer
is OK, and have the current document count and size in memory.
Returns 1 if everything is OK, else 0.

If runtime stops or aborts while the output buffer is
still being built, a restart will safely recover the
contents as long as no data was lost on the file.

=head2 add()

 &Buffer::add($xml);

Add an XML chunk to the current buffer and updates current 
document count and size in memory.

=head2 save()

 $filename = &Buffer::save();
 if ( !$filename ) {
     die "Cannot Buffer::save";
 } else {
     print STDERR "New XML file $filename saved\n";
 }

Save the current buffer into "xml-add/" as an appropriote integer
name, such as "xml-add/$N.xml", where $N will be determined at the point 
of saving as the next biggest integer.   Returns the filename used
if everything is OK, else returns undef.  This needs to be called
explicitly so the variables $Buffer::docs and $Buffer:.size should be
checked to determine when this should be done.

=head2 close()

 &Buffer::close();

Close the output buffer.

=head1 VARIABLES and PARAMETERS

Global variables are of two kinds.
There are those intended to define
characteristics of general use.  These should be set by the user
before the functions are used, but reasonable defaults are used.

=head2 BUFFER

name of the output buffer file that collects XML chunks.  Don't
include the randomising string "$$" if you want this file to
be available during a restart.

=head2 HEADER

text to enter at the front of a sequence of <documentRecord> elements.

=head2 FOOTER

text to enter at the end of a sequence of <documentRecord> elements.

=head2 verbose

set to a non-zero value if more debugging shoulöd be reported to STDERR.

Then the are variables that are read-only and define current buffer
statistics.

=head2 size

Count of characters in the current buffer.

=head2 docs

Count of documents, as determined by occurrences of <documentRecord> elements.


=head1 SEE ALSO

Alvis::Pipeline

=head1 AUTHOR

Wray Buntine, E<lt>buntine@hiit.fiE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Wray Buntine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut




#############################################
#  parameters - fixed per instance
our $BUFFER="building.xml-ish";
our $HEADER='<?xml version="1.0" encoding="UTF-8"?>
<documentCollection xmlns="http://alvis.info/enriched/" version="1.1">
';
our $TRAILER='</documentCollection>
';

#############################################
#  run time variables
our $docs = 0;
our $size = 0;
our $verbose = 0;

############################################
#
#  add XML chunk
sub add() {
  my $xml = shift();
  my $xc = $xml;
  my $count = $xc =~ s/<\/documentRecord>//g;
  #  now save
  print ABUF $xml,"\n";
  if ( $verbose ) {
    my $tt = Time::Simple->new;
    print STDERR "Docs of $count of size " . length($xml) . " added at time "
      . $tt->format . "\n";
  }
  $docs += $count;
  $size += length($xml);
}

sub close() {
  CORE::close(ABUF);
}

############################################
#
#  make sure the output XML buffer file is in OK state
#  and open it for append, as filehandle ABUF
#  and set $docs, $size
#  return 0 on fatal error, after printing error message
sub fix() {
  $docs = 0;
  $size = 0;
  if ( ! -f $BUFFER ) {
    #  start new one
    if ( ! open(ABUF,">>$BUFFER") ) {
      print STDERR "Cannot open $BUFFER: $!\n";
      return 0;
    }
    select((select(ABUF), $| = 1)[0]);
    print ABUF $HEADER;
  } else {
    #  check old one first
    if ( ! open(ABUF,"<$BUFFER") ) {
      print STDERR "Cannot open $BUFFER: $!\n";
      return 0;
    }
    #  its a UTF-8 file, so have to read it all
    #  since cannot start half way through
    my $last = "";
    my $last2 = "";
    my $last3 = "";
    while ( ($_=<ABUF>) ) {
      if (  ! /^\s+$/ ) {
	$last3 = $last2;
	$last2 = $last;
	$last = $_;
	if ( /<\/documentRecord/ ) {
	  $docs++;
	}
	$size += length($_);
      }
    }
    $last = $last3 . $last2 . $last;
    if ( $last !~ /<documentCollection [^>]+>\s*$/
	 && $last !~ /<\/documentRecord>\s*$/ ) {
      print STDERR "Output buffer $BUFFER in unstable state\n";
      if (  $last =~ /<\/documentCollection>/ ) {
	print STDERR "  has been completed, so move manually\n";
      }
      return 0;
    }
    CORE::close(ABUF);
    # now open for append
    if ( ! open(ABUF,">>$BUFFER") ) {
      print STDERR "Cannot open $BUFFER: $!\n";
      return 0;
    }
    select((select(ABUF), $| = 1)[0]);
  }
  1;
}

############################################
#
#  rename output XML buffer file to xml-add/N.xml for some N
#  and create a new output XML buffer file, name is returned;
#  return undef on fatal error, after printing error message
sub save() {
  print ABUF $TRAILER; 
  CORE::close(ABUF);
  #  determine next available name
  if ( ! opendir(XA,"xml-add") ) {
    print STDERR "Cannot opendir xml-add/: $!\n";
    return undef;
  }
  my $latest = 0;
  while ( ($_=readdir(XA)) ) {
    if ( /^([0-9]+).xml$/ ) {
      if ( $latest < int($1) ) {
	$latest = int($1);
      }
    }
  }
  closedir(XA);
  if ( ! $latest ) {
    if ( !opendir(XA,"xml") ) {
      print STDERR "Cannot opendir xml/: $!\n";
      return undef;
    }
    while ( ($_=readdir(XA)) ) {
      if ( /^([0-9]+).xml$/ ) {
	if ( $latest < int($1) ) {
	  $latest = int($1);
	}
      }
    }
    closedir(XA);
  }
  $latest++;
  my $nf = "xml-add/$latest.xml";
  #   now save
  rename($BUFFER,$nf);
  if ( ! &fix() ) {
    return undef;
  }
  return $nf;
}

1;
