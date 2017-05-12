package Biblio::Citation::Parser;

######################################################################
#
# Biblio::Citation::Parser; 
#
######################################################################
#
#  This file was originally part of ParaCite Tools, based at 
#  http://paracite.eprints.org/developers/
#
#
#  Copyright (c) 2004 University of Southampton, UK. SO17 1BJ.
#
#  ParaTools is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  ParaTools is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with ParaTools; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
######################################################################

use strict;
use vars qw($VERSION);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = ( 'parse', 'new' );

$VERSION = "1.10";

=pod

=head1 NAME

B<Biblio::Citation::Parser> - citation parsing framework 

=head1 DESCRIPTION

Biblio::Citation::Parser provides generic methods for reference parsers. This
class should not be used directly, but rather be overridden by specific
parsers.  Parsers that extend the Parser class must provide at least
the two methods defined here to ensure compatibility.

=head1 METHODS

=over 4

=item $cite_parser = Biblio::Citation::Parser-E<gt>new()

The new() method creates a new parser instance. 

=cut

sub new
{
	my($class) = @_;
	my $self = {};
	return bless($self, $class);
}

=pod

=item $metadata = $parser-E<gt>parse($reference)

The parse() method takes a reference and returns the extracted metadata.

=cut

sub parse
{
	my($self, $ref) = @_;
	die "This method should be overridden.\n";
}

1;

__END__

=pod

=back

=head1 AUTHOR

Mike Jewell <moj@ecs.soton.ac.uk>

=cut
