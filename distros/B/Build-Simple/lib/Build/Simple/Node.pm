package Build::Simple::Node;
{
  $Build::Simple::Node::VERSION = '0.002';
}

use Moo;

has phony => (
	is => 'ro',
);

has skip_mkdir => (
	is => 'ro',
	default   => sub {
		my $self = shift;
		return $self->phony;
	},
);

has dependencies => (
	is => 'ro',
	default => sub { [] },
);

has action => (
	is => 'ro',
	default => sub { sub {} },
);

sub run {
	my ($self, $name, $graph, $options) = @_;
	if (!$self->phony and -e $name) {
		my @files = grep { !$graph->_is_phony($_) } sort @{ $self->dependencies };
		return if sub { -d $_ or -M $name <= -M $_ or return 0 for @files; 1 }->();
	}
	File::Path::mkpath(File::Basename::dirname($name)) if !$self->skip_mkdir;
	$self->action->(name => $name, dependencies => $self->dependencies, %{$options});
	return;
}

1;

#ABSTRACT: A Build::Simple node


__END__
=pod

=head1 NAME

Build::Simple::Node - A Build::Simple node

=head1 VERSION

version 0.002

=for Pod::Coverage run

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

