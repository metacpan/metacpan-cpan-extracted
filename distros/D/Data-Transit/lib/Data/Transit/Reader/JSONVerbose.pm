package Data::Transit::Reader::JSONVerbose;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.8.04';

use parent 'Data::Transit::Reader';

use JSON;
use List::MoreUtils qw(any);

sub new {
	my ($self, %args) = @_;
	for my $handler_class (keys %{$args{handlers}}) {
		$args{handlers}{$handler_class} = $args{handlers}{$handler_class}->getVerboseHandler();
	}
	return $self->SUPER::new(%args);
}

sub _decode {
	my ($self, $data) = @_;
	return decode_json($data);
}

sub _cache {
	my ($self, $data) = @_;
	return $data;
}

sub _convert {
	my ($self, $json) = @_;

	if (ref($json) eq 'HASH') {
		return $self->SUPER::_convert([%$json]) if any {$_ =~ /^~#/} keys %$json;
	}

	return $self->SUPER::_convert($json);
}

1;
