package AMF::Connection::Message;

use strict;
use Carp;

use AMF::Connection::OutputStream;
use AMF::Connection::InputStream;

use AMF::Connection::MessageBody;
use AMF::Connection::MessageHeader;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	
	my $self = {
		'encoding' => 0, # default is AMF0 encoding
		'bodies' => [],
		'headers' => []
		};

	return bless($self, $class);
	};

sub serialize {
	my ($class, $stream) = @_;

	croak "Stream $stream is not a valid output stream"
		unless(ref($stream) and $stream->isa("AMF::Connection::OutputStream"));

	# we default to AMF0 encoding
	$stream->writeByte(0x00);
	$stream->writeByte($class->getEncoding());

	$stream->writeInt(scalar(@{$class->{'headers'}}));
	foreach my $header (@{$class->{'headers'}}) {
		my $name =$header->getName();
		$stream->writeInt(length($name));
		$stream->writeBuffer($name);

		$stream->writeByte($header->isRequired());

		$stream->writeLong(-1);

		# TODO - make sure Storable::AMF does not store string "true" as boolean - or make sure value is right typed
		$stream->writeAMFData( $class->getEncoding(), $header->getValue() );
		};

	$stream->writeInt(scalar(@{$class->{'bodies'}}));
	foreach my $body (@{$class->{'bodies'}}) {
		my $target = $body->getTarget();
		$stream->writeInt(length($target));
		$stream->writeBuffer($target);

		my $response = $body->getResponse();
		$stream->writeInt(length($response));
		$stream->writeBuffer($response);

		$stream->writeLong(-1);
		$stream->writeAMFData( $class->getEncoding(), $body->getData() );
		};

	}; 

sub deserialize {
	my ($class, $stream) = @_;

	$class->{'headers'} = [];
	$class->{'bodies'} = [];

        $stream->readByte();

        my $sent_encoding = $stream->readByte();
	# need to make AMF1 returned encoding the same as AMF0 - see more about the bug at http://balazs.sebesteny.com/footprints-in-blazeds/
        $class->setEncoding( ( $sent_encoding!=0 and $sent_encoding!=3 ) ? 0 : $sent_encoding );

        my $totalHeaders = $stream->readInt();
	for(my $i=0;$i<$totalHeaders;$i++) {
		my $header = new AMF::Connection::MessageHeader();

		my $strLen = $stream->readInt();
		$header->setName( $stream->readBuffer($strLen) );

		$header->setRequired( $stream->readByte() );

                $stream->readLong();
		$header->setValue( $stream->readAMFData() ); # we deparse the next read value out

                $class->addHeader( $header );
		};

	my $totalBodies = $stream->readInt();
	for(my $i=0;$i<$totalBodies;$i++) {
		my $body = new AMF::Connection::MessageBody();

		my $strLen = $stream->readInt();
		$body->setTarget( $stream->readBuffer($strLen) );

		$strLen = $stream->readInt();
		$body->setResponse( $stream->readBuffer($strLen) );

		# TODO - make sure we deal properly with avm+ object marker stuff here - and have message containing multiple encodings
                $stream->readLong();
		$body->setData( $stream->readAMFData() ); # we deparse the next read value out

                $class->addBody( $body );
		};
	}; 

sub addBody {
	my ($class, $body) = @_;

	croak "Body $body is not a valid message body"
		unless(ref($body) and $body->isa("AMF::Connection::MessageBody"));

	push @{ $class->{'bodies'} }, $body;
	};

sub addHeader {
	my ($class, $header) = @_;

	croak "Header $header is not a valid message header"
		unless(ref($header) and $header->isa("AMF::Connection::MessageHeader"));

	push @{ $class->{'headers'} }, $header;
	};

sub getHeaders {
	my ($class) = @_;

	return $class->{'headers'};
	};

sub getBodies {
	my ($class) = @_;

	return $class->{'bodies'};
	};

sub setEncoding {
        my ($class, $encoding) = @_;

	croak "Unsupported AMF encoding $encoding"
		unless( $encoding==0 or $encoding==3 );

        $class->{'encoding'} = $encoding;
        };

sub getEncoding {
        my ($class) = @_;

        return $class->{'encoding'};
        };


1;
__END__

=head1 NAME

AMF::Connection::Message - Encapsulates a request or response protocol packet/message

=head1 SYNOPSIS

  # ...

  my $request = new AMF::Connection::Message;
  $request->setBody( $body );

  # ..


=head1 DESCRIPTION

The AMF::Connection::Message class encapsulates a request or response protocol packet/message.

=head1 SEE ALSO

Storable::AMF0, Storable::AMF3, AMF::Connection::MessageHeader, AMF::Connection::MessageBody

=head1 AUTHOR

Alberto Attilio Reggiori, <areggiori at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alberto Attilio Reggiori

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
