package AMF::Connection::MessageBody;

use strict;
use Carp;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my ($target,$response,$data) = @_;
	
	my $self = {
		'target' => $target,
		'response' => $response,
		'data' => $data # we might want to have some kind of mapper between remote objects and local / user registered ones
		};

	return bless($self, $class);
	};

sub setTarget {
	my ($class, $target) = @_;

	$class->{'target'} = $target;
	};

sub getTarget {
	my ($class) = @_;

	return $class->{'target'};
	};

sub setResponse {
	my ($class, $response) = @_;

	$class->{'response'} = $response;
	};

sub getResponse {
	my ($class) = @_;

	return $class->{'response'};
	};

sub setData {
	my ($class, $data) = @_;

	$class->{'data'} = $data;
	};

sub getData {
	my ($class) = @_;

	return $class->{'data'};
	};

# HTTP::Response-ish methods ...

sub is_error {
	my ($class) = @_;

	return ($class->{'target'} =~ m|onStatus|) ? 1 : 0 ;
	};

sub is_success {
	my ($class) = @_;

	return ($class->{'target'} =~ m|onResult|) ? 1 : 0 ;
	};

sub is_debug {
	my ($class) = @_;

	return ($class->{'target'} =~ m|onDebug|) ? 1 : 0 ;
	};

1;
__END__

=head1 NAME

AMF::Connection::MessageBody - Encapsulates a request or response protocol packet/message body.

=head1 SYNOPSIS

  # ...

  my $request = new AMF::Connection::Message;
  my $body = new AMF::Connection::MessageBody;
  $body->setTarget('myService.myOperation);
  $body->setResponse('/1');
  $body->setData( { 'param1' => 'value1', 'param2' => 'value2' } );
  $request->setBody( $body );

  # ..


=head1 DESCRIPTION

The AMF::Connection::MessageBody class encapsulates a request or response protocol packet/message body.

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
