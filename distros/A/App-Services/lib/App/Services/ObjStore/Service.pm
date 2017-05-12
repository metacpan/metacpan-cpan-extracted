package App::Services::ObjStore::Service;
{
  $App::Services::ObjStore::Service::VERSION = '0.002';
}

use Moose;

use common::sense;

with 'App::Services::Logger::Role';

use KiokuDB;

has kdb => ( is => 'rw' );

has kdb_dsn => (
	is      => 'rw',
	default => sub { "dbi:SQLite:dbname=" . $_[0]->obj_store_file },
	lazy    => 1,
);

has obj_store_file => (
	is       => 'rw',
	required => 1,
);

has label => (
	is      => 'rw',
	default => sub { $$ },
);

sub init_object_store {
	my $s = shift or die;

	$s->kdb( KiokuDB->connect( $s->kdb_dsn, create => 1 ) );

	$s->kdb or $s->log->logconfess();

}

sub delete {
	my $s = shift or die;

	$s->kdb->delete(@_);

}

sub delete_object_store {
	my $s = shift or die;

	unlink $s->obj_store_file if -f $s->obj_store_file;

	$s->log->warn("Couldn' t delete object store ") if -d $s->obj_store_file;

	$s->kdb(undef);

	return $s->kdb;

}

sub add_object {

	my $s   = shift or die;
	my $obj = shift or $s->log->fatal( $s->label . " : No object passed " );
	my $id  = shift;

	my $kdb = $s->kdb;
	my $log = $s->log;

	$log->debug( $s->label . " Entering add_object " );

	unless ($kdb) {
		$s->log->logconfess(
			$s->label . " : Must call 'init_object_store' first " );
	}

	my $new_id;

	my $rc;

	do {
		$log->debug( $s->label . " : Inserting obj " );

		eval {
			($new_id) = $kdb->txn_do(
				scope => 1,
				body  => sub {
					if ($id) {
						$kdb->insert( $id => $obj );

					}
					else {
						$kdb->insert($obj);

					}
				}
			);
		};

		if ($@) {
			$s->log->warn(
				    $s->label
				  . " : failed to commit to("
				  . $s->kdb
				  . ") : [$@],
		  sleeping
		  for random interval
		  and retrying "
			);
			my $i = rand(0.1);
			sleep $i;

		}
		else {
			$log->debug( $s->label . " : successfully comitted " );
			$rc = 1;
		}

	} until ($rc);

	return $new_id;

}

sub get_object {
	my $s  = shift or die;
	my $id = shift or $s->log->fatal( $s->label . " : No object id passed " );

	my $kdb = $s->kdb;

	unless ($kdb) {
		$s->log->logconfess(
			$s->label . " : Must call 'init_object_store' first " );
	}

	my $obj;

	$kdb->txn_do(
		scope => 1,
		body  => sub {
			$obj = $kdb->lookup($id);
		}
	);

	return $obj;
}

sub all_objects {
	my $s = shift or die;

	my $kdb = $s->kdb;

	unless ($kdb) {
		$s->log->logconfess(
			$s->label . " : Must call 'init_object_store' first " );
	}

	return $kdb->all_objects->items;

}

no Moose;

1;

__END__

=pod

=head1 NAME

App::Services::ObjStore::Service

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
