package Data::Transit::Reader;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.8.04';

use JSON;

sub new {
	my ($class, %args) = @_;
	return bless {
		%args,
		cache => [],
		cache_counter => 0,
	}, $class;
}

sub read {
	my ($self, $json) = @_;
	return $self->_convert($self->_decode($json));
}

sub _convert_from_cached {
	my ($self, $data) = @_;
	return $self->_convert($self->_cache($data, 1));
}

sub _cache {
	my ($self, $data, $cacheable) = @_;
	return $self->{cache}[$1] if $data =~ /^\^(\d+)$/;
	$self->{cache}->[$self->{cache_counter}++] = $data if length($data) > 3 && $cacheable;
	return $data;
}

sub _convert {
	my ($self, $json) = @_;
	if (ref($json) eq 'ARRAY') {
		return $self->_convert($json->[1]) if $json->[0] eq "~#'";

		if ($self->_cache($json->[0], $json->[0] =~ /^~#/) =~ /^~#(.+)$/) {
			return $self->{handlers}{$1}->fromRep(@$json[1..$#$json]);
		}

		return $self->_convert_map($json) if $json->[0] eq "^ ";
		return [map {$self->_convert($_)} @$json];
	} else {
		return "" if $json eq "~_";
		return $json ? 1 : 0 if JSON::is_bool($json);
		return 1 if $json eq "~?t";
		return 0 if $json eq "~?f";
		return $1 if $json =~ /^~.(.+)$/;
		return $json;
	}
}

sub _convert_map {
	my ($self, $map) = @_;
	my %map = @$map[1..$#$map];
	return {map {$self->_convert_from_cached($_) => $self->_convert($map{$_})} keys %map};
}

1;
