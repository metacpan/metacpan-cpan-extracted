# Copyright (C) 2004 Domingo Alcázar Larrea
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the version 2 of the GNU General
# Public License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

package DIME::Parser;
$DIME::Parser::VERSION = '0.05';
use 5.008;
use strict;
use warnings;
use IO::Wrap;
use DIME::Message;
use DIME::Record;
use DIME::Payload;
use IO::Scalar;


# Preloaded methods go here.

my $DIME_VERSION = 1;

sub new
{
	my $class = shift;	
	my $this = {
			
		};
	return bless $this, $class;
}

# Read a DIME message and parse it extracting all
# the Payloads
sub parse
{
	my $self = shift;
	my $in = shift;
	my $buf;
	# Create a new Message
	my $message = DIME::Message->new();
	my $read_bytes = 0;
	while(!$in->eof())
	{	
		# Create a new Payload
		my $payload = DIME::Payload->new();
		my $end = 0;
		my $start = 1;
		while(!$end)
		{
			# Create a new Record and read from stream...		
			my $record = DIME::Record->new();
			$read_bytes += $record->read($in);
			if($start)
			{
				$payload->type($record->type());
				$payload->id($record->id());
				$payload->tnf($record->tnf());
				$start = 0;
			}
			$payload->add_record($record);
			$end =1 if($record->cf()==0);
		}
		# Add payload to the Message
		$message->add_payload($payload);
	}
	return $message;
}

sub parse_data
{
	my $self = shift;
	my $ref_data = shift;
	my $io = IO::Scalar->new($ref_data);
	my $message = $self->parse($io);
	$io->close;
	return $message;
}

1;

=encoding UTF-8

=head1 NAME

DIME::Parser - parse a DIME message

=head1 SYNOPSIS

  use DIME;
  blah blah blah

=head1 ABSTRACT

  This should be the abstract for DIME.
  The abstract is used when making PPD (Perl Package Description) files.
  If you don't want an ABSTRACT you should also edit Makefile.PL to
  remove the ABSTRACT_FROM option.

=head1 DESCRIPTION

Stub documentation for DIME, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
