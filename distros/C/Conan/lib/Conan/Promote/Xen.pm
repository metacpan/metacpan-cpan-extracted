package Conan::Promote::Xen;

sub new {
	my $class = shift;
	my $args = {
		@_,
	};

	return bless $args => $class;
}

sub update_image {
	my $self = shift;
	my ($node, $target) = @_;

	print "D: Upgrading $node to $target\n";
}

1;
