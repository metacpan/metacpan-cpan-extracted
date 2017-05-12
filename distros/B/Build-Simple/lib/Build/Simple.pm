package Build::Simple;
{
  $Build::Simple::VERSION = '0.002';
}

use Moo;

use Carp;
use File::Path;

use Build::Simple::Node;

has _nodes => (
	is => 'ro',
	default => sub { {} },
);

sub _get_node {
	my ($self, $key) = @_;
	return $self->_nodes->{$key};
}

sub has_node {
	my ($self, $key) = @_;
	return exists $self->_nodes->{$key};
}

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak("File '$name' already exists in database") if !$args{override} && $self->_get_node($name);
	my $node = Build::Simple::Node->new(%args, phony => 0);
	$self->_nodes->{$name} = $node;
	push @{ $self->_get_node($_)->dependencies }, $name for @{ $args{dependents} };
	return;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak("Phony '$name' already exists in database") if !$args{override} && $self->_get_node($name);
	my $node = Build::Simple::Node->new(%args, phony => 1);
	$self->_nodes->{$name} = $node;
	push @{ $self->_get_node($_)->dependencies }, $name for @{ $args{dependents} };
	return;
}

sub _node_sorter {
	my ($self, $current, $callback, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	my $node = $self->_get_node($current) or Carp::croak("Node $current doesn't exist");
	local $loop->{$current} = 1;
	$self->_node_sorter($_, $callback, $seen, $loop) for @{ $node->dependencies };
	$callback->($current, $node);
	return;
}

sub _sort_nodes {
	my ($self, $startpoint) = @_;
	my @ret;
	$self->_node_sorter($startpoint, sub { push @ret, $_[0] }, {}, {});
	return @ret;
}

sub _is_phony {
	my ($self, $key) = @_;
	my $node = $self->_get_node($key);
	return $node ? $node->phony : 0;
}

sub run {
	my ($self, $startpoint, %options) = @_;
	$self->_node_sorter($startpoint, sub { $_[1]->run($_[0], $self, \%options) }, {}, {});
	return;
}

1;

#ABSTRACT: A minimalistic dependency system


__END__
=pod

=head1 NAME

Build::Simple - A minimalistic dependency system

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Build::Simply is a simple but effective dependency engine. It tries to support 

=head1 METHODS

=head2 add_file($filename, %options)

Add a file to the build graph. It can take the following options:

=over 4

=item * action

A subref to the action that needs to be performed.

=item * dependencies

The nodes the action depends on. Defaults to an empty list.

=item * skip_mkdir

Block C<mkdir(dirname($filename))> from being executed before the action. Defaults to false.

=back

=head2 add_phony($filename, %options)

Add a phony dependency to the graph. It takes the same options as add_file does, except that skip_mkdir defaults to true.

=head2 run($goal, %options)

Make all of C<$goal>'s dependencies, and then C<$goal> itself.

=head2 has_node($filename)

Returns true if a node exists in the graph, returns false otherwise.

=for Pod::Coverage has_file

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

