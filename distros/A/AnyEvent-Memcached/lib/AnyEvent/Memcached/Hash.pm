package #hide
	AnyEvent::Memcached::Hash;

use common::sense 2;m{
use strict;
use warnings;
}x;
use Carp;
use String::CRC32 'crc32';

sub new {
	my $self = bless {}, shift;
	my %args = @_;
	$self->{buckets} = $args{buckets};
	$self;
}

sub set_buckets { shift->{buckets} = @_ == 1 ? $_[0] : \@_ }

sub hash { (crc32($_[1]) >> 16) & 0x7fff; }

sub peers {
	my $self = shift;
	my ($hash,$real,$peers) = @_;
	$peers ||= {};
	my $peer = $self->{buckets}->peer( $hash );
	push @{ $peers->{$peer} ||= [] }, $real;
	return $peers;
}

sub hashes {
	my $self = shift;
	$self->{buckets} or croak "No buckets set during hashes";
	my $keys = shift;
	my $array;
	if (ref $keys and ref $keys eq 'ARRAY') {
		$array = 1;
	} else {
		$keys = [$keys];
	}
	my %peers;
	for my $keyx (@$keys) {
		my ($hash,$real) = ref $keyx ?
			(int($keyx->[0]),     $keyx->[1]) :
			($self->hash($keyx),  $keyx);
		$self->peers($hash,$real,\%peers);
	}
	return \%peers;
}
*servers = \&hashes;

1;
