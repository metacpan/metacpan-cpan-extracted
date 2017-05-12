package App::Services::DB::Container::SQLite;
{
  $App::Services::DB::Container::SQLite::VERSION = '0.002';
}

use Moo;
#use MooX::Types::MooseLike::Base;
use Bread::Board;

use App::Services::Logger::Container;
use App::Services::DB::Container;

extends 'App::Services::DB::Container';

sub BUILD {
	$_[0]->build_container;
}

has db_file => (
	is      => 'rw',
	isa     => sub { ref($_[0]) eq 'SCALAR' and $_[0] =~ /^\w$/ },
	default => sub { ':memory:' },
);

has log_conf => (
	is => 'rw',
	isa     => sub { ref($_[0]) eq 'SCALAR' or (ref($_[0]) eq 'REF' and ref($$_[0])) eq 'SCALAR'},

);

has +name => (
	is      => 'rw',
	isa     => sub { ref($_[0]) eq 'SCALAR' and $_[0] =~ /^\w$/ },
	default => sub { 'sqlite' },
);

sub build_container {
	my $s = shift;
	
	my $log_cntnr = App::Services::Logger::Container->new(
		log_conf => $s->log_conf,
		name => 'log'
	);

	my $dsn = "dbi:SQLite:dbname=" . $s->db_file;

	my $db_cntnr = App::Services::DB::Container->new(
		dsn         => $dsn,
		db_user     => '',
		db_password => '',
		log_conf    => $s->log_conf,
		name        => 'db'
	);

	container $s => as {

		service 'db_exec_svc' => (
			class        => 'App::Services::DB::Exec::Service',
			dependencies => {
				logger_svc => depends_on('log/logger_svc'),
				db_conn    => depends_on('db/db_conn_svc'),
			}
		);

	};

	$s->add_sub_container($log_cntnr);
	$s->add_sub_container($db_cntnr);

	return $s;
}

no Moose;

1;

__END__

=pod

=head1 NAME

App::Services::DB::Container::SQLite

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
