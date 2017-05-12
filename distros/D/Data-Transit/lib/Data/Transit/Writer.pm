package Data::Transit::Writer;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.8.04';

use JSON;
use Carp qw(confess);

sub new {
	my ($class, $output, %args) = @_;
	bless {
		%args,
		output => $output,
		cache => {},
		cache_counter => 0,
	}, $class;
}

sub write {
	my ($self, $data, @remainder) = @_;
	confess("write only takes one argument") if scalar(@remainder) > 0;

	my $output = $self->{output};
	if (ref($data) ne '') {
		print $output $self->_encode($self->_convert($data));
	} else {
		print $output $self->_encode($self->_wrap_top_level_scalar($self->_convert($data)));
	}
}

sub _wrap_top_level_scalar {
	my ($self, $converted_data) = @_;
	return ["~#'", $converted_data];
}

sub _convert {
	my ($self, $data) = @_;
	return $self->_convert_array($data) if ref($data) eq 'ARRAY';
	return $self->_convert_map($data) if ref($data) eq 'HASH';
	return $data if ref($data) eq '';
	return $self->_convert_custom($data);
}

sub _cache_convert {
	my ($self, $data) = @_;
	return $self->_convert($self->_cache($data));
}

sub _cache {
	my ($self, $data) = @_;
	if (length($data) > 3 && defined $self->{cache}{$data}) {
		return "^$self->{cache}{$data}";
	} else {
		$self->{cache}{$data} = $self->{cache_counter}++;
	}
	return $data;
}

sub _convert_array {
	my ($self, $array) = @_;
	return [map {$self->_convert($_)} @$array];
}

sub _convert_map {
	my ($self, $map) = @_;
	return $self->_wrap_map(map {
		$self->_cache_convert($_) => $self->_convert($map->{$_})
	} keys %$map);
}

sub _wrap_map {
	my ($self, @converted_map) = @_;
	return ["^ ", @converted_map];
}

sub _convert_custom {
	my ($self, $data) = @_;
	my $handler = $self->{handlers}->{ref($data)};
	return $self->_convert($self->_wrap_custom($self->_cache("~#" . $handler->tag($data)), $handler->rep($data)));
}

sub _wrap_custom {
	my ($self, $tag, $handled_data) = @_;
	return [$tag, $handled_data];
}

1;
