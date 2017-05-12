package App::Services::ZeroMQ::Container;
{
  $App::Services::ZeroMQ::Container::VERSION = '0.002';
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
	default => sub {
		\qq/ 
log4perl.rootLogger=INFO, main
log4perl.appender.main=Log::Log4perl::Appender::Screen
log4perl.appender.main.layout   = Log::Log4perl::Layout::SimpleLayout
/;
	},
);

has +name => (
	is => 'rw',

	#	isa     => 'Str',
	default => sub { 'zero_mq_container' },
);

sub build_container {
	my $s = shift;

	my $log_cntnr = App::Services::Logger::Container->new(
		log_conf => $s->log_conf,
		name     => 'log'
	);

	container $s => as {

		service 'ipc_zeromq_svc' => (
			class        => 'App::Services::IPC::ZeroMQ::Service',
			dependencies => {
				logger_svc     => depends_on('log/logger_svc'),
			}
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

App::Services::ZeroMQ::Container

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
