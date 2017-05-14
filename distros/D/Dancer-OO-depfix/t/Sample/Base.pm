package Sample::Base;
use strict;
use parent 'Dancer::OO::Object';
use Dancer::OO::Dancer;

get '' => wrap {
	my ($self, $context, $params) = @_;
	template $self, 'index', { p => $params };
};

1;
