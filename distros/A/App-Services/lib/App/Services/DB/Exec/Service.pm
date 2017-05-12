package App::Services::DB::Exec::Service;
{
  $App::Services::DB::Exec::Service::VERSION = '0.002';
}

use Moo;

use common::sense;

with 'App::Services::Logger::Role';
with 'App::Services::DB::Conn::Role';

use DBI;

has sql => ( is => 'rw', );

has return_code => (
	is      => 'rw',
	default => sub {1},
);

has error_message => (
	is      => 'rw',
	default => sub {''},
);

has array_ref => (
	is      => 'rw',
	default => sub { undef },
);

sub validate {
	my $s = shift or die;

	$s->dbh or confess("dbh handle required for &write_run");

	unless ( $s->dbh ) {
		$s->error_message("ERROR: NO DATABASE CONNECTION DEFINED");
		$s->return_code(undef);
		return undef;
	}

	unless ( $s->sql ) {
		$s->error_message("ERROR: NO SQL DEFINED TO EXECUTE");
		$s->return_code(undef);
		return undef;
	}
}

sub exec_sql {
	my $s = shift or die;

	my $sql = shift or $s->log->logconfess("No SQL supplied to exec_sql");
	$s->log->info($sql);
	$s->sql($sql);
	return $s->exec;

}

sub exec {
	my $s = shift or die;

	return unless $s->validate;

	my $sql_text = $s->sql;

	my $sth = $s->dbh->prepare($sql_text);

	unless ($sth) {
		$s->error_message( $s->dbh->errstr );
		$s->return_code(undef);
		return undef;
	}

	my $rc = $sth->execute();

	unless ($rc) {
		$s->error_message( $s->dbh->errstr );
		$s->return_code(undef);
		return undef;
	}

	my $ra = $sth->fetchall_arrayref( {} );

	unless ($ra) {
		$s->error_message( $s->dbh->errstr );
		$s->return_code(undef);
		return undef;
	}

	$s->array_ref($ra);

	return $ra;
}

sub exec_scalar {
	my $s = shift or die;

	return unless $s->validate;

	$s->log->debug( $s->sql );

	return $s->dbh->selectrow_array( $s->sql );

}

no Moose;

1;

__END__

=pod

=head1 NAME

App::Services::DB::Exec::Service

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
