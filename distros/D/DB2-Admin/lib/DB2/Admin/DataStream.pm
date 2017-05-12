#
# DB2::Admin::DataStream - Decode self-describing binary data stream used
#                          for snapshot, monitor switches, and events
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
# $Id: DataStream.pm,v 145.2 2007/11/20 21:53:44 biersma Exp $
#

package DB2::Admin::DataStream;

use strict;
use Carp;

use DB2::Admin::Constants;
use DB2::Admin::DataElement;

#
# Create a new DataStream object, which is a container for one or more
# DataElement objects.
#
# Parameters:
# - String with binary data
# Returns:
# - Newly created object
#
sub new {
    my ($class, $data) = @_;

    my ($size, $type, $element) = unpack("l s s", $data);
    my $binary = substr($data, 8, $size);

    confess "Invalid amount data passed in (have " . length($data) .
      " expected " . ($size + 8) . ")"
        unless (length($data) == $size + 8);
    confess "Not a DataStream: have type [$type], not 1"
      unless ($type == 1);

    my $name = $DB2::Admin::Constants::constant_index->{'Element'}{$element};
    if (defined $name) {
	$name =~ s/^SQLM_ELM_// ||
	  confess "Cannot remove prefix from element name [$name]";
    } else {
	$name = $element;
    }

    return bless { 'Name'    => $name,
                   'Element' => $element,
                   'Data'    => $binary,
                 }, $class;
}


#
# Return the name of the current tree node, e.g. 'DBASE'
#
sub getName {
    my ($this) = @_;

    return $this->{'Name'};
}


#
# Returns a description (from the IBM header files) of the current
# tree node, e.g. "database information".
#
sub getDescription {
    my ($this) = @_;

    my $elem = $this->{'Element'};
    my $name = $DB2::Admin::Constants::constant_index->{'Element'}{$elem};
    return "unknown element $elem" unless (defined $name);
    return $DB2::Admin::Constants::constant_info->{$name}{'Comment'};
}


#
# Return all children of the current node, which can be a mixture of
# DB2::Admin::DataStream and DB2::Admin::DataElement objects.
#
sub getChildnodes {
    my ($this) = @_;

    unless (defined $this->{'Children'}) {
        my $children = [];
        my $offset = 0;
        my $data_length = length($this->{'Data'});
        while ($offset < $data_length) {
            my ($size, $type, $element) =
              unpack("l s s", substr($this->{Data}, $offset, 8));
	    if ($size > $data_length) {
		print STDERR "DATA ERROR: read size [$size] type [$type] elem [$element] at offset (add 8) [$offset]\n";
	    }
            if ($type == 1) {
                push @$children, DB2::Admin::DataStream::->
                  new(substr($this->{Data}, $offset, $size+8));
            } else {
                push @$children, DB2::Admin::DataElement::->
                  new($element, $type, substr($this->{Data}, $offset+8, $size));
            }
            $offset += $size + 8;
        }
        confess "Did not consume all data.  Offset is [$offset], data length is [$data_length]"
          unless ($offset == $data_length);
        $this->{'Children'} = $children;
    }
    return @{ $this->{'Children'} };
}


#
# Return a hash-reference with the names and display values of all
# direct children that are leaf nodes (DB2::Admin::DataElement).
#
sub getValues {
    my ($this) = @_;

    my $retval = {};
    foreach my $child ($this->getChildnodes()) {
        next unless ($child->isa("DB2::Admin::DataElement"));
        my $name = $child->getName();
        my $value = $child->getValue();
        confess "Duplicate element [$name]"
          if (defined $retval->{$name});
        $retval->{$name} = $value;
    }
    return $retval;
}


#
# Find the first node matching a path description
#
sub findNode {
    my ($this, $path) = @_;

    if ($path =~ m!/!) {        # Need recursive lookup
        my ($first, $rest) = ($path =~ m!^(\w+)/(.*)$!);
        foreach my $child ($this->getChildnodes()) {
            next unless ($child->getName() eq $first &&
                         $child->isa("DB2::Admin::DataStream"));
	    my $retval = $child->findNode($rest);
	    return $retval if (defined $retval);
        }
    } else {                    # Leaf lookup
        foreach my $child ($this->getChildnodes()) {
            next unless ($child->getName() eq $path);
	    return $child;
        }
    }
    return;
}


#
# Find all nodes matching a path description
#
sub findNodes {
    my ($this, $path) = @_;

    my @retval;
    if ($path =~ m!/!) {        # Need recursive lookup
        my ($first, $rest) = ($path =~ m!^(\w+)/(.*)$!);
        foreach my $child ($this->getChildnodes()) {
            next unless ($child->getName() eq $first &&
                         $child->isa("DB2::Admin::DataStream"));
            push @retval, $child->findNodes($rest);
        }
    } else {                    # Leaf lookup
        foreach my $child ($this->getChildnodes()) {
            push @retval, $child if ($child->getName() eq $path);
        }
    }
    return @retval;
}


#
# Find the value of the first leaf node matching a patch description
#
sub findValue {
    my ($this, $path) = @_;

    my $node = $this->findNode($path);
    if (defined $node) {
	return $node->getValue();
    }
    return;
}


#
# Recursively display all information
#
sub Format {
    my ($this, $depth) = @_;

    $depth ||= 0;
    my $retval = '';
    my $name = $this->getName();
    my $desc = $this->getDescription();
    $retval .= ('  ' x $depth) . "- $name ($desc):\n";
    foreach my $child ($this->getChildnodes()) {
        if ($child->isa("DB2::Admin::DataStream")) {
            $retval .= $child->Format($depth + 1);
        } elsif ($child->isa("DB2::Admin::DataElement")) {
            my $name = $child->getName();
            my $desc = $child->getDescription();
            my $value = $child->getValue();
            $retval .= ('  ' x $depth) . "  - $name ($desc): $value\n";
        } else {
            confess "Unexpected child [$child]";
        }
    }
    return $retval;
}


1;


__END__


=head1 NAME

DB2::Admin::DataStream - Support for DB2 self-describing data stream

=head1 SYNOPSIS

  use DB2::Admin::DataStream;

  #
  # Get binary data from snapshot or event file/pipe, then...
  #
  my $stream = DB2::Admin::DataStream::->new($binary_data);

  #
  # For quick and dirty formatting (or figuring out the format)
  #
  print $stream->Format();

  #
  # Access to a particular node (two alternatives)
  #
  my $node = $stream->findNode('SWITCH_LIST/UOW_SWITCH/SWITCH_SET_TIME/SECONDS');
  my $time_sec = $node->getValue();
  my $time_msec = $stream->findValue('SWITCH_LIST/UOW_SWITCH/SWITCH_SET_TIME/MICROSEC');

  #
  # Access to many similar nodes
  #
  my @appl_info = $stream->findNodes('APPL/APPL_INFO');

  #
  # Access to child nodes
  #
  my @children = $stream->getChildnodes();
  my $name = $children[0]->getName();
  my $desc = $children[0]->getDescription();

  #
  # Access to all direct data elements of a node (hash-reference)
  #
  my $values = $node->getValues();

=head1 DESCRIPTION

The DB2 administrative API returns several types of return values in a
so-called 'self-describing data stream'.  The data stored in event
files or written to event pipes is in the same format.  The data
format and all element types plus their values, are described in the
"System Monitor Guide and Reference" (SC09-4847).

This module provides a method to decode this data stream and convert
it to a perl object that provides access to the data.  The code
postpones the work decoding the data until is is queried for, which in
most cases is considerably faster than decoding it all upfront.

Access is provided using an API loosely moduled after C<XML::LibXML>,
though it intentionally is far less powerful.  Like an XML document,
the data stream is a hierarchical tree.  Each node in the tree is a
C<Db2API::DataStream> object; the leaves actually hold the data and
are C<DB2::Admin::DataElement> objects.

=head1 METHODS

=head2 new

This method receives a binary datastream and creates a
C<DB2::Admin::DataStream> object.  Later accesses to the object will
cause it to create child objects of both the C<DB2::Admin::DataStream>
and C<DB2::Admin::DataElement> classes.

=head2 getName

This method returns the name of a node, e.g. 'DBASE'.  The
C<DB2::Admin::DataElement> class supports the same method, so this can
safely be invoked on any object.

=head2 getDescription

This method returns the description of a node, e.g. 'database
information'.  This description is parsed from the DB2 header files at
C<DB2::Admin> module compile time.  The C<DB2::Admin::DataElement>
class supports the same method, so this can safely be invoked on any
object.

=head2 getChildnodes

This method returns all children of the current node, which can be a
mixture of C<DB2::Admin::DataStream> and C<DB2::Admin::DataElement> objects.
This is only useful when traversing all data or when the contents of
the data is unknown; in most cases, the C<findNode>, C<findNodes> or
C<findValue> methods should be used instead.

=head2 getValues

This method returns a hash-reference with the names and display values
of all direct children that are leaf nodes
(C<DB2::Admin::DataElement>).  This is useful for those tree nodes
that are known to be containers for a set of leaves, e.g. 'DBASE' or
'APPL_INFO'.  If you need to process a large number of data elements
that are all children of the same node, this is the most efficient
method to get at the data.

=head2 findNode

This method returns the first node that matches a path expression.  It
is related to C<findNodes>, which returns all nodes matching an
expression, and C<findValue>, which returns the value of the first
node matching an expression.

In order to explain path expressions, suppose an application snapshot
contains the following data (the example uses simplified C<Format> output):

  - DATA_COLLECTED
    - APPL
      - APPL_INFO
        - APPL_ID: appl_info_1
        - AGENT_ID: 12
        ... data omitted ...
      - OTHER_APPL_DATA
      - MORE_APPL_DATA
    - APPL
      - APPL_INFO
        - APPL_ID: appl_info_2
        - AGENT_ID: 20
        ... data omitted ...
      - OTHER_APPL_DATA
      - MORE_APPL_DATA

Starting with the main 'DATA_COLLECTED' node, which is returned by the
C<GetSnapshot> method, there are multiple 'APPL' nodes, each of which
contains an 'APPL_INFO' node, which in turn contains leaf elements for
'APPL_ID' and 'AGENT_ID'.

For the above data, the following can be done:

  my $node1 = $snapshot->findNode('APPL/APPL_INFO'); # First APPL node's APPL_INFO node
  my $agent_id = $appl_info->findNode('AGENT_ID')->getValue(); # 12
  my $appl_id = $appl_info->findValue('APPL_ID'); # appl_info_1
  my @all_appl_info = $snapshot->findNodes('APPL/APPL_INFO'); # All APPL_INFO nodes

When following a path, these methods all start looking at the children
of the current C<DB2::Admin::ParseStream> object.  Each forward slash
implies a single step further down the hierarchical tree.  The results
may be C<DB2::Admin::DataStream> or C<DB2::Admin::DataElement>
objects; the former can be used for further searches, while the latter
can be used to get values.

=head2 findNodes

This method returns all nodes that matche a path expression.  It is
related to C<findNode>, which returns the first node matching an
expression, and C<findValue>, which returns the value of the first
node matching an expression.  See C<findNode> for more details.

=head2 findValue

This method returns the value of the first node that matches a path
expression.  It is related to C<findNode>, which returns the first
node matching an expression, and C<findNodes>, which returns all nodes
matching an expression.  See C<findNode> for more details.

=head2 Format

This method takes a C<DB2::Admin::DataStream> object and returns a
string suitable for display purposes.  This is useful to study the
data structure when writing or debugging applications.

=head1 AUTHOR

Hildo Biersma

=head1 SEE ALSO

DB2::Admin(3), DB2::Admin::Constants(3), DB2::Admin::DataElement(3)

=cut
