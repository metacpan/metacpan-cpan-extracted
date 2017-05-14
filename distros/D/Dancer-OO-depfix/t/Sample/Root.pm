package Sample::Root;
use parent 'Sample::Base';
use Dancer::OO::Dancer;
use strict;

post "" => wrap {
	my ($self, $c, $p) = @_;
	template $self, "index", { c => $c, p => $p };
};

1;
