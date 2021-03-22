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


package DIME::Tools;
$DIME::Tools::VERSION = '0.05';
use 5.008;
use strict;
use warnings;


1;

=encoding UTF-8

=head1 NAME

DIME::Tools - modules for parsing and generate DIME messages

=head1 SYNOPSIS

Generating DIME messages

		my $payload = DIME::Payload->new();
		$payload->attach(Path => "/mydata/index.html",
		                 MIMEType => 'text/html',
		                 Dynamic => 1);

		my $payload2 = DIME::Payload->new();
		$payload2->attach( Data => "HELLO WORLD!!!",
		                   MIMEType => 'text/plain' );

		my $message = DIME::Message->new();

        my $payload = DIME::Payload->new();
        $payload->attach(Path => "/mydata/index.html",
                         MIMEType => 'text/html',
                         Dynamic => 1);

		$message->add_payload($payload);
		$message->add_payload($payload2);

		# Print the encoded message to STDOUT
		$message->print(\*STDOUT);

Parsing DIME messages

        my $parser = DIME::Parser->new();

		# Open a file with a dime encoded message
        $f = IO::File->new("dime.message","r");
        my $message = $parser->parse($f);
        $f->close();

		# Print the content of each payload to STDOUT
        for my $i ($message->payloads())
        {
                print $i->print_content(\*STDOUT);
        }


=head1 DESCRIPTION

DIME-tools is a collection of DIME:: modules for parsing and generating DIME encoded messages
(Direct Internet Message Encapsulation).
DIME-tools support single-record and chunked payloads for sending big attachments.

This distribution hasn't been actively developed since 2004.
Subsequent releases have been to get the distribution following CPAN conventions,
as there is one distribution depending on it

=head1 GENERATING MESSAGES

For any content you want to send in a message, you have to create a Payload object:

	my $payload = DIME::Payload->new();
        $payload->attach(Path => "/mydata/index.html",
                         MIMEType => 'text/html',
                         Dynamic => 1);

With the attach method you can specify the next keys:

=over 4

=item B<Path>:

the name of the file you want to attach to the payload object.
If the data you want to attach isn't in a file, you can use the Data key.

=item B<Data>:

it's the reference to a scalar in which you store the data you want to attach.

=item B<Dynamic>:

if Path is declared, the data is not loaded fully in memory.
The only that you attach to the payload object is the name of the file of the Path key,
not the content itself.

=item B<Chunked>:

if it's declared, it represents the size of the chunk records in bytes.
If you don't declare it, the message will not be chunked.

=item B<MIMEType>:

the type of the payload. It must be a string with a MIME standard type. Other possibility is to use URIType.

=item B<URIType>:

specifies an URI that defines that type of the content.

=back

=head1 ATTACH A PAYLOAD TO A MESSAGE

	my $message = DIME::Message->new();
	$message->add_payload($payload);

=head1 PRINT A ENCODED MESSAGE

	# Print prints to any IO::Handle
	$message->print(\*STDOUT);

	or

	# print_data returns a reference to a scalar
	print ${$message->print_data()};

=head1 PARSING MESSAGES

All you have to do is create a DIME::Parser object and call the parse method with a IO::Handle to a DIME message. Then you can iterate over the $message->payloads() array to get the contents of the message:

	my $parser = DIME::Parser->new();
	$f = IO::File->new("dime.message","r");
	my $message = $parser->parse($f);
	$f->close();
	for my $i ($message->payloads())
	{
	        print $i->print_content(\*STDOUTs);
	}

You can also call to parse_data if you have a DIME message in a scalar variable:

	my $dime_message;
	my $message = $parser->parse_data(\$dime_message);

And call print_content_data if what you want is to get a reference to the content-data.

=head1 SEE ALSO

Direct Internet Message Encapsulation draft:
 http://www.gotdotnet.com/team/xml_wsspecs/dime/dime.htm

L<DIME::Message>,
L<DIME::Payload>,
L<DIME::Record>.

=head1 AUTHOR

Domingo Alcazar Larrea, E<lt>dalcazar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE


Copyright (C) 2004 Domingo Alcázar Larrea

This program is free software; you can redistribute it and/or
modify it under the terms of the version 2 of the GNU General
Public License as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

=cut
