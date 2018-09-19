package App::BorgRestore::PathTimeTable::Memory;
use v5.14;
use strictures 2;

use Function::Parameters;

=head1 NAME

App::BorgRestore::PathTimeTable::Memory - In-Memory preparation of new archive data

=head1 DESCRIPTION

This is used by L<App::BorgRestore> to add new archive data into the database.
Data is prepared in memory first and only written to the database once.

=cut

method new($class: $deps = {}) {
	return $class->new_no_defaults($deps);
}

method new_no_defaults($class: $deps = {}) {
	my $self = {};
	bless $self, $class;
	$self->{deps} = $deps;
	$self->{lookuptable} = [{}, 0];
	$self->{nodes_to_flatten} = [];
	$self->{nodes} = [];
	return $self;
}

method set_archive_id($archive_id) {
	$self->{archive_id} = $archive_id;
}

method add_path($path, $time) {
	my @components = split /\//, $path;

	my $node = $self->{lookuptable};

	if ($path eq ".") {
		if ($time > $$node[1]) {
			$$node[1] = $time;
		}
		return;
	}

	# each node is an arrayref of the format [$hashref_of_children, $mtime]
	# $hashref_of_children is undef if there are no children
	for my $component (@components) {
		if (!defined($$node[0]->{$component})) {
			$$node[0]->{$component} = [undef, $time];
		}
		# update mtime per child
		if ($time > $$node[1]) {
			$$node[1] = $time;
		}
		$node = $$node[0]->{$component};
	}
}

method save_nodes() {
	$self->_save_node($self->{archive_id}, undef, $self->{lookuptable});
}

method _save_node($archive_id, $prefix, $node) {
	for my $child (keys %{$$node[0]}) {
		my $path;
		$path = $prefix."/" if defined($prefix);
		$path .= $child;

		my $time = $$node[0]->{$child}[1];
		$self->{deps}->{db}->add_path($archive_id, $path, $time);

		$self->_save_node($archive_id, $path, $$node[0]->{$child});
	}
}

1;

__END__
