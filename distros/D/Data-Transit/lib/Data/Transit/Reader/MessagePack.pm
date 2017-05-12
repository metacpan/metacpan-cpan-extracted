package Data::Transit::Reader::MessagePack;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.8.04';

use parent 'Data::Transit::Reader';

use Data::MessagePack;

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{mp} = Data::MessagePack->new();
	return $self;
}

sub _decode {
	my ($self, $data) = @_;
	return $self->{mp}->unpack($data);
}

1;
