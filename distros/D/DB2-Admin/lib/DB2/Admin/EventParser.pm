#
# DB2::Admin::EventParser - Parse DB2 event monitor files while
#                           the database writes them, optionally
#                           deleting file completely read.
#
# Copyright (c) 2007, Morgan Stanley & Co. Incorporated
# See ..../COPYING for terms of distribution.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation;
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301  USA
#
# THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER
# MATERIALS CONTRIBUTED IN CONNECTION WITH THIS DB2 ADMINISTRATIVE API
# LIBRARY:
#
# THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS
# SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING
# THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE
# TERMS THAT MAY APPLY.
#
# $Id: EventParser.pm,v 145.2 2007/11/20 21:53:53 biersma Exp $
#

package DB2::Admin::EventParser;

use strict;
use Carp;
use DB2::Admin::DataStream;
use Params::Validate qw(:all);
use IO::File;

#
# Constructor
#
# Required parameters:
# - Directory: name of directory used to store files
#
sub new {
    my $class = shift;
    my %params = validate(@_, { 'Directory' => 1,
				'Debug'     => 0,
                              });

    my $dirname = $params{'Directory'};
    confess "Directory '$dirname' does not exist"
      unless (-d $dirname);

    return bless { 'Directory' => $dirname,
		   'Debug'     => $params{Debug} || 0,
		 }, $class;
}


#
# Read the next event from the file.  This returns one record at a
# time, or undef if there is no data to be read.
#
sub GetEvent {
    my $this = shift;

    #
    # If we have no file name and offset, get the first file available
    #
    unless (defined $this->{'File'}) {
        delete $this->{'fh'};
        my @fnames = $this->_getfiles();
        return unless (@fnames);
        $this->{'File'} = $fnames[0];
    }
    unless (defined $this->{'fh'}) {
        my $fname = "$this->{'Directory'}/$this->{'File'}";
        #
        # Specifying mode 0 implies sysopen() and O_RDONLY
        #
        my $fh = $this->{'fh'} = IO::File->new($fname, 0) ||
          confess "Cannot open file [$fname]: $!";
        binmode($fh);           # For Windows
        if ($this->{'Offset'}) {
            sysseek($fh, $this->{'Offset'}, 0) ||
              confess "Cannot seek to offset [$this->{'Offset'}]: $!";
        }
    }

    #
    # If we're at the first file and offset zero (or no offset at
    # all), try and read an event header
    #
    my $fh = $this->{'fh'};
    if ($this->{'File'} =~ /^0+\.evt$/i &&
        ! $this->{'Offset'}) {
        print STDERR "EventParser: Try to read event file header\n"
	  if ($this->{Debug});

        my $length = 12;
        my ($data, $read);
        $read = sysread($fh, $data, $length);
        confess "Could not read header (only $read bytes): $!"
          unless ($read == $length);
        my ($order, $size, $version) = unpack("l l l", $data);
        #print STDERR "DEBUG: event header: Have order [$order], size [$size], version [$version]\n";
        if ($version < 6) {
            confess "Have event file in version [$version], which is not self-descr
ibing";
        }
        # FIXME: if the data doesn't look right, seek back to offset zero
        $this->{'Offset'} = sysseek($fh, 0, 1);
    }

    #
    # Read an event.  If this fails, check if there is a newer
    # file available.  If so, switch to that file.
    #
    my $length = 8;
    my ($data, $read);
    $read = sysread($fh, $data, $length);
    if ($read == 0) {           # No data
        my @fnames = $this->_getfiles();
        if (@fnames && $this->{'File'} ne $fnames[-1]) {
            print STDERR "EventParser: Nothing read and new files present; close [$this->{File}] and switch to next file\n"
	      if ($this->{Debug});
            my $prev;
            foreach my $i (@fnames) {
                if (defined $prev && $prev eq $this->{'File'}) {
                    print STDERR "EventParser: next file is [$i]\n"
		      if ($this->{Debug});
                    $this->{'File'} = $i;
                    delete $this->{'Offset'};
                    delete $this->{'fh'};
                    return $this->GetEvent();
                }
                $prev = $i;
            }
            #
            # If we get here, the current file was deleted while we
            # were reading ti - very bad (maybe a bad SetPosition()
            # call?).  Pick the first file again.
            #
            print STDERR "EventParser: Could not find current file in list\n"
	      if ($this->{Debug});
            delete $this->{'File'};
            delete $this->{'Offset'};
            delete $this->{'fh'};
            return $this->GetEvent();
        }
        return undef;           # End of event files
    }
    confess "Could not read elements (only $read bytes): $!"
      unless ($read == $length);
    my ($size, $type, $element) = unpack("l s s", $data);

    # use DB2::Admin::Constants;
    #my $elem_name = DB2::Admin::Constants::->Lookup('Element', $element) ||
    #  '<unknown>';
    #print STDERR "DEBUG: Have size [$size], type [$type], element [$element] ($elem_name)\n"
;
    confess "Type is [$type], not 1" unless ($type == 1);
    $read = sysread($fh, $data, $size, $length);
    confess "Could not relevant data (only got $read of $size bytes): $!"
      unless ($read == $size);
    return DB2::Admin::DataStream::->new($data);
}


#
# This function will delete all event files that have been completely
# processed.  If we are currently positioned in file 5, this will
# delete files 0..4 if they still exist.
#
sub Cleanup {
    my $this = shift;

    my @fnames = $this->_getfiles();
    while (@fnames) {
        my $file = shift @fnames;
        last if ($file ge $this->{'File'});
        $file = "$this->{'Directory'}/$file";
        unlink($file) ||
          confess "Cannot unlink file [$file]: $!";
    }
    return $this;
}


#
# Inquire to current file and offset.  This can be used to resume
# reading at a later time by calling SetPosition().  This is
# especially useful if the event monitor is set to APPEND across
# database restarts.
#
# Parameters: none
# Returns: hash-ref with File and Offset / undef if no record has been read
#
sub InquirePosition {
    my $this = shift;

    return unless (defined $this->{'File'});
    if (defined $this->{'fh'}) {
        $this->{'Offset'} = sysseek($this->{'fh'}, 0, 1);
    }
    return { 'File'   => $this->{'File'},
             'Offset' => $this->{'Offset'},
           };
}


#
# Set the file and offset to read.  Used internally to go to the next
# file; can be used to continue where a previous run left off
# (e.g. if event monitor is set to APPEND not REPLACE).
#
# Hash with named parameters:
# - File
# - Offset
#
sub SetPosition {
    my $this = shift;
    my %params = validate(@_, { 'File'   => 1,
                                'Offset' => 1,
                              });

    my $fname = $params{'File'};
    confess "File '$fname' does not exist in directory '$this->{Directory}'"
      unless (-f "$this->{Directory}/$fname");
    delete $this->{'fh'};
    $this->{'File'} = $fname;
    $this->{'Offset'} = $params{'Offset'};
    return $this;
}

# ------------------------------------------------------------------------

#
# PRIVATE helper method: list all event files available,
# in sorted order.
#
sub _getfiles {
    my $this = shift;

    opendir(EVENTS, $this->{'Directory'}) ||
      confess "Cannot opendir [$this->{'Directory'}]: $!";
    my @entries = sort readdir EVENTS;
    closedir EVENTS;

    my @retval;
    foreach my $i (@entries) {
        next if (substr($i, 0, 1) eq '.'); # ., .., .dotfile
        next if ($i eq 'db2event.ctl');
        if ($i =~ /^\d+\.evt$/i) {
            push @retval, $i;
            next;
        }
        print STDERR "EventParser: Unexpected file [$i] in event directory [$this->{'Directory'}]\n"
	  if ($this->{Debug});
    }
    return @retval;
}


1;				# End on a positive note


__END__


=head1 NAME

DB2::Admin::EventParser - Support for processing DB2 event monitor files

=head1 SYNOPSIS

  use DB2::Admin::EventParser;

  my $parser = DB2::Admin::EventParser::->new('Directory' => '/tmp/eventdir');
  while (1) {
    my $start = time();

    # Process all events since last time
    my $events = 0;
    while (my $event = $parser->GetEvent()) {
        ... process event ...
        $events++;
    }
    my $elapsed = 0;
    if ($events) {
        # Clean up events fully processed
        $parser->Cleanup();
        my $end = time();
        $elapsed = $end - $start;
    }
    if ($elapsed > $scan) {
        print "Took [$elapsed] seconds, scan rate [$scan]\n";
    } else {
        print "Will sleep [", ($scan - $elapsed), "] seconds\n";
        sleep ($scan - $elapsed);
    }
  }

=head1 DESCRIPTION

DB2 event monitors can write to a file, to a named pipe, or to DB2
tables.  The C<DB2::Admin::DataStream> class cna be used to parse events
written to a file or named pipe.

When events monitors write to a file, DB2 weill switch to a new file
if the current file is full; the reading application is responsible to
clean up the old file.  After a database restart, DB2 continues
appending to the latest file.

This class is intended to help process such files.  It depends on the
C<DB2::Admin::DataStream> module to parse file contents.  The value it
provides is in switching from file to file, being able to restart
reading at a desired point, and deleting files that have been fully
processed.

=head1 METHODS

=head2 new

This method creates a new parser object.  It takes a single named
parameter, C<Directory>, which is the name of the directory that
contains the DB2 event monitor files.

The parser object maintains internal styate for the file currently
being processed and the position within that file.

=head2 GetEvent

This method retrives the next event from the event file.  It returns a
C<DB2::Admin::DataStream> object, or C<undef> if all events have been
read.

=head2 Cleanup

This method cleans up all files that have been fully processed,
assuming the parser has swicthed to a the next event file.

This method is not implicit in C<GetEvent> because having a separate
method gives the programmer the opportunity to delay file deletion
until the events has been archived or acted upon.

=head2 InquirePosition

This method returns a hash reference with C<File> and C<Offset> fields
describing the current event file and position within the file.  It
returns C<undef> if the parser has not started reading any event file.
The return value can be saved at event monitor shutdown time and later
be fed into C<SetPosition> to restart where the event monitor left
off.

=head2 SetPosition

This method takes two named parameters, C<File> and C<Offset>, as
returned by a previous call to C<InquirePosition>.  It can be used to
resume processing at a position previously inquired and saved.

WARNING: feeding random offsets into this module will cuase the parser
to return invalid data and possibly crash.

=head1 AUTHOR

Hildo Biersma

=head1 SEE ALSO

DB2::Admin(3) DB2::Admin::DataStream(3), DB2::Admin::DataElement(3)

=cut
