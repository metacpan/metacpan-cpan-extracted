package App::Services::ObjStore::Container;
{
  $App::Services::ObjStore::Container::VERSION = '0.002';
}

use Moose;

use common::sense;

#use MooX::Types::MooseLike::Base;

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

has obj_store_file => (
	is      => 'rw',
	default => sub {
		my $tmp = $ENV{TMP} || '/tmp';
		return "${tmp}/.app-services-obj-store-$$.db";
	}
);

has dsn => (
	is      => 'rw',
	default => sub { "dbi:SQLite:dbname=" . $_[0]->obj_store_file },
	lazy    => 1,
);

has +name => (
	is => 'rw',

	#	isa     => 'Str',
	default => sub { 'obj_store' },
);

sub build_container {
	my $s = shift;

	my $log_cntnr = App::Services::Logger::Container->new(
		log_conf => $s->log_conf,
		name     => 'log'
	);

	container $s => as {

		service 'obj_store_file' => $s->obj_store_file;
		service 'kdb_dsn'        => $s->dsn;

		service 'obj_store_svc' => (
			class        => 'App::Services::ObjStore::Service',
			dependencies => {
				logger_svc     => depends_on('log/logger_svc'),
				obj_store_file => 'obj_store_file',
				kbs_dsb        => 'kdb_dsn',
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

App::Services::ObjStore::Container

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
