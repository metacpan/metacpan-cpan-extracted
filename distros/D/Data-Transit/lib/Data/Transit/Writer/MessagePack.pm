package Data::Transit::Writer::MessagePack;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.8.04';

use parent 'Data::Transit::Writer';

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->{mp} = Data::MessagePack->new();
	return $self;
}

sub _encode {
	my ($self, $data) = @_;
	return $self->{mp}->pack($data);
}

1;
