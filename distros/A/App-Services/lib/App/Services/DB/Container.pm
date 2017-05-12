package App::Services::DB::Container;
{
  $App::Services::DB::Container::VERSION = '0.002';
}

use Moo;

use common::sense;

use Bread::Board;

extends 'Bread::Board::Container';

use App::Services::Logger::Container;

sub BUILD {
	$_[0]->build_container;
}

has dsn => (
	is => 'rw',

	#	isa     => 'Str',
	default => sub { 'dbi:SQLite:dbname=tmp.sqlite' },
);

has db_user => (
	is => 'rw',

	#	isa     => 'Str',
	default => sub { 'king' },
);

has db_password => (
	is => 'rw',

	#	isa     => 'Str',
	default => sub { 'kong' },
);

has log_conf => (
	is      => 'rw',
	default => sub { 'log4perl.conf' },
);

has +name => (
	is => 'rw',

	#	isa     => 'Str',
	default => sub { 'db' },
);

sub build_container {
	my $s = shift;

	my $log_cntnr = App::Services::Logger::Container->new(
		log_conf => $s->log_conf,
		name     => 'log'
	);

	container $s => as {

		service 'dsn'         => $s->dsn;
		service 'db_user'     => $s->db_user;
		service 'db_password' => $s->db_password;

		service 'db_conn_svc' => (    #-- raw DBI database handle
			class        => 'App::Services::DB::Conn::Service',
			dependencies => {
				logger_svc  => depends_on('log/logger_svc'),
				dsn         => 'dsn',
				db_user     => 'db_user',
				db_password => 'db_password',
			}
		);

		service 'db_exec_svc' => (
			class        => 'App::Services::DB::Exec::Service',
			dependencies => {
				logger_svc => depends_on('log/logger_svc'),
				db_conn    => depends_on('db_conn_svc'),
			}
		);

	};

	$s->add_sub_container($log_cntnr);

	return $s;
}

no Moo;

1;

__END__

=pod

=head1 NAME

App::Services::DB::Container

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
