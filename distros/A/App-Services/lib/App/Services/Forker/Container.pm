package App::Services::Forker::Container;
{
  $App::Services::Forker::Container::VERSION = '0.002';
}

use Moose;

use common::sense;

use Bread::Board;

extends 'Bread::Board::Container';

use App::Services::Logger::Container;

sub BUILD {
	$_[0]->build_container;
}

has log_conf => (
	is      => 'rw',
	default => sub { 'log4perl.conf' },
);

has child_objects => (
	is     => 'rw',
	isa    => 'ArrayRef',
	required => 1,

);

has child_actions => (
	is       => 'rw',
	isa      => 'CodeRef',
	required => 1,
);

has +name => (
	is  => 'rw',
	default => sub { 'forker' },
);

sub build_container {
	my $s = shift;

	my $log_cntnr = App::Services::Logger::Container->new(
		log_conf => $s->log_conf,
		name     => 'log'
	);

	container $s => as {

		service child_objects => $s->child_objects;
		service child_actions => $s->child_actions;

		service 'forker_svc' => (
			class        => 'App::Services::Forker::Service',
			dependencies => {
				logger_svc    => depends_on('log/logger_svc'),
				child_objects => 'child_objects',
				child_actions => 'child_actions'
			},
		);

	};

	$s->add_sub_container($log_cntnr);

	return $s;
}

no Moose;

1;

__END__

=pod

=head1 NAME

App::Services::Forker::Container

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
