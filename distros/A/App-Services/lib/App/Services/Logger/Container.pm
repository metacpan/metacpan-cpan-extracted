package App::Services::Logger::Container;
{
  $App::Services::Logger::Container::VERSION = '0.002';
}

use Moo;
use Bread::Board;

extends 'Bread::Board::Container';

sub BUILD {
	$_[0]->build_container;
}

has log_conf => (
	is      => 'rw',
	default => sub { " 
log4perl.rootLogger=INFO, main
log4perl.appender.main=Log::Log4perl::Appender::Screen
log4perl.appender.main.layout   = Log::Log4perl::Layout::SimpleLayout
" },
);

has +name => (
	is      => 'rw',
	default => sub { 'logger' },
);

sub build_container {
	my $s = shift;

	return container $s => as {

		service 'log_conf' => $s->log_conf;

		service 'logger_svc' => (
			class        => 'App::Services::Logger::Service',
			lifecycle    => 'Singleton',
			dependencies => { log_conf => 'log_conf' },

		);

	};

}

no Moo;

1;

__END__

=pod

=head1 NAME

App::Services::Logger::Container

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
