package AMF::Connection::MessageHeader;

use strict;
use Carp;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my ($name, $value, $required) = @_;
	
	my $self = {};

	$self->{'name'} = $name;

	$self->{'value'} = $value;

	$self->{'required'} = ($required=~m/(1|yes)/) ? 1 : 0;

	return bless($self, $class);
	};

sub isRequired {
	my ($class) = @_;

	return $class->{'required'};
	};

sub getName {
	my ($class) = @_;

	return $class->{'name'};
	};

sub getValue {
	my ($class) = @_;

	return $class->{'value'};
	};

sub setName {
	my ($class, $name) = @_;

	$class->{'name'} = $name;
	};

sub setValue {
	my ($class, $value) = @_;

	$class->{'value'} = $value;
	};

sub setRequired {
	my ($class, $required) = @_;

	$class->{'required'} = ($required) ? 1 : 0 ;
	};


1;
__END__

=head1 NAME

AMF::Connection::MessageHeader - Encapsulates a request or response protocol packet/message header.

=head1 SYNOPSIS

  # ...
  my $header = new AMF::Connection::MessageHeader;
  $header->setName( 'Foo' );
  $header->setValue( 'Bar' );
  $header->setRequired( 1 );

  # ...
  if( $header->isRequired ) {
	# 1...
  } else {
	# 2...
	};

  # ..
  my $header2 = new AMF::Connection::MessageHeader($name,$value,0);


=head1 DESCRIPTION

The AMF::Connection::MessageHeader class encapsulates a request or response protocol packet/message header.

=head1 SEE ALSO

AMF::Connection::Message

=head1 AUTHOR

Alberto Attilio Reggiori, <areggiori at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alberto Attilio Reggiori

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
