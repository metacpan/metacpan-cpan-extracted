#####################################################################
#
# ASP::NextLink - Perl implementation of the ASP
#                 Content-Linking component
#
# Author: Tim Hammerquist
# Revision: 0.11
#
#####################################################################
#
# Copyright 2000 Tim Hammerquist.  All rights reserved.
#
# This file is distributed under the Artistic License.
# See http://www.perl.com/language/misc/Artistic.html or
# the license that comes with your perl distribution.
#
# Contact me at cafall@voffice.net with any comments,
# flames, queries, suggestions, or general curiosity.
#
#####################################################################
package ASP::NextLink;

use strict;
use CGI::Carp;
use vars qw( $VERSION );

$VERSION = '0.11';

sub new {
	my $class = shift;
	die "Cannot call class method on an object" if ref $class;
	my $linkfile = $main::Server->MapPath( shift );
	my $self = {};
	bless $self, $class;
	$self->parse_linkfile( $linkfile );
	$self;
}

sub parse_linkfile {
	my ($self, $linkfile, $idx) = (shift, shift, 0);
	die "Cannot call object method on class"  unless ref $self;
	open LNX, "<$linkfile" or die "Can't open $linkfile: $!\n";
	while ( <LNX> ) {
		chomp;
		if ( /^([^\t]+)\t([^\t]+)\t?.*$/ ) {
			$idx++;
			$self->{_url}{$main::Server->MapPath($1)} = $idx;
			$self->{_idx}{$idx} = [ $1, $2 ];
		}
	}
	close LNX;
	$self->{_file} = $linkfile;
	$self->{_count} = $idx;
	1;
}

=head1 NAME

ASP::NextLink - Perl implementation of the NextLink ASP component

=head1 SYNOPSIS

	require ASP::NextLink;
	$nl = new ASP::NextLink('linkfile.ext');

	$current = $nl->GetListIndex;
	for $idx (1..$nl->GetListCount) {
		my $url =	$nl->GetNthURL($idx);
		my $desc =	$nl->GetNthDescription($idx);
		if ($idx == $current) {
			print qq(<A href="$url">$desc</A><BR>);
		}
		else {
			print qq(<B>$desc</B>);
		}
	}

=head1 DESCRIPTION

ASP::NextLink is a Perl implementation of MSWC.NextLink, ASP's
content-linking component for use with Apache::ASP.

=head1 NOTES

ASP::NextLink is NOT functionally equivalent to MSWC.NextLink.
Whereas each method of MSWC.NextLink takes a file argument,
ASP::NextLink takes a file argument ONLY in the constructor
( ASP::NextLink->new("linkfile") ). new() parses the linkfile
given; the information derived from this linkfile is subsequently
available only through the object returned by new().

Attempts to call object methods on a class and attempts to call
class methods on an object will both trigger an exception.

However, in the interest of portability of algorithms to ASP::NextLink,
indexes passed to the GetNth*() methods remain 1-based, as they are in
MSWC.NextLink.

=head1 USE

=head2 require ASP::NextLink;

=head1 METHOD REFERENCE

=head2 new( linkfile )

The new() class method accepts a virtual or relative path.
(Paths handed to new() are run through the $Server->MapPath() method.)
new() returns a reference to an ASP::NextLink object.

	my $linkfile = "/links.txt";
	my $nl = ASP::NextLink->new( $linkfile );

From now we will refer to the object returned by new() as $nl.

=cut


=head2 GetListCount()

Returns the number of links (lines containing tab-separated fields)
in link file.

	my $count = $nl->GetListCount();

=cut

sub GetListCount {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	$self->{_count};
}

=head2 GetListIndex()

Index of the current page in the link file.

=cut

sub GetListIndex {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	$self->{_url}{$ENV{SCRIPT_FILENAME}}
		or die "Current page not found in $self->{_file}";
}

=head2 GetPreviousURL()

URL of the previous page in the link file.

=cut

sub GetPreviousURL {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	my $idx = $self->GetListIndex - 1;
	exists( $self->{_idx}{$idx} )
		? $self->{_idx}{$idx}[0] : undef;
}

=head2 GetPreviousDescription()

Description of the previous page in the link file.

=cut

sub GetPreviousDescription {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	my $idx = $self->GetListIndex - 1;
	exists( $self->{_idx}{$idx} )
		? $self->{_idx}{$idx}[1] : undef;
}

=head2 GetNextURL()

URL of the next page in the link file.

=cut

sub GetNextURL {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	my $idx = $self->GetListIndex + 1;
	exists( $self->{_idx}{$idx} )
		? $self->{_idx}{$idx}[1] : undef;
}

=head2 GetNextDescription()

Description of the next page in the link file.

=cut

sub GetNextDescription {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	my $idx = $self->GetListIndex + 1;
	exists( $self->{_idx}{$idx} )
		? $self->{_idx}{$idx}[1] : undef;
}

=head2 GetNthURL( n )

URL of the nth page in the link file.
NOTE: Index is 1-based, NOT zero-based.

=cut

sub GetNthURL {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	my $idx = shift;
	$self->{_idx}{$idx}[0];
}

=head2 GetNthDescription( n )

Description of the nth page in the link file.
NOTE: Index is 1-based, NOT zero-based.

=cut

sub GetNthDescription {
	my $self = shift;
	die "Cannot call object method on class"  unless ref $self;
	my $idx = shift;
	$self->{_idx}{$idx}[1];
}

=head1 AUTHOR

Tim Hammerquist E<lt>F<cafall@voffice.net>E<gt>

=head1 HISTORY

=over 4

=item Version 0.11

First functional release

=back

=head1 SEE ALSO

ASP(3)

=cut
1;
__END__

