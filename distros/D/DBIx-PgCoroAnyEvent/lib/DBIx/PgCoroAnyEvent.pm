{

	package DBIx::PgCoroAnyEvent;

	our $VERSION = "0.04";

=head1 NAME
 
DBIx::PgCoroAnyEvent - DBD::Pg + Coro + AnyEvent
 
=head1 SYNOPSIS
 
  use DBI;
  $dbh = DBI->connect("dbi:Pg:dbname=$dbname", $username, $auth, { RootClass =>"DBIx::PgCoroAnyEvent",  %rest_attr});

=cut

}
{

	package DBIx::PgCoroAnyEvent::db;
	use DBD::Pg ':async';
	use base 'DBD::Pg::db';
	use strict;
	use warnings;

	sub prepare {
		my ($dbh, $statement, @attribs) = @_;
		return undef if !defined $statement;
		$attribs[0]{pg_async} = PG_ASYNC + PG_OLDQUERY_WAIT;
		DBD::Pg::db::prepare($dbh, $statement, @attribs);
	}

	sub selectrow_arrayref {
		my ($dbh, $stmt, $attr, @bind) = @_;
		my $sth = ((ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr)) or return;
		$sth->execute(@bind) or return;
		my $row = $sth->fetchrow_arrayref() and $sth->finish;
		return $row;
	}

	sub selectrow_array {
		my ($dbh, $stmt, $attr, @bind) = @_;
		my $rowref = $dbh->selectrow_arrayref($stmt, $attr, @bind) or return;
		@$rowref;
	}

	sub selectall_arrayref {
		my ($dbh, $stmt, $attr, @bind) = @_;
		my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr)
			or return;
		$sth->execute(@bind) || return;
		my $slice = $attr->{Slice};    # typically undef, else hash or array ref
		if (!$slice and $slice = $attr->{Columns}) {
			if (ref $slice eq 'ARRAY') {    # map col idx to perl array idx
				$slice = [@{$attr->{Columns}}];    # take a copy
				for (@$slice) {$_--}
			}
		}
		my $rows = $sth->fetchall_arrayref($slice, my $MaxRows = $attr->{MaxRows});
		$sth->finish if defined $MaxRows;
		return $rows;
	}

	sub do {
		my ($dbh, $statement, $attr, @params) = @_;
		my $sth = $dbh->prepare($statement, $attr) or return undef;
		$sth->execute(@params) or return undef;
		my $rows = $sth->rows;
		($rows == 0) ? "0E0" : $rows;
	}
}

{

	package DBIx::PgCoroAnyEvent::st;
	use Coro;
	use AnyEvent;
	use Coro::AnyEvent;
	use base 'DBD::Pg::st';

	sub execute {
		my ($sth, @vars) = @_;
		my $res = $sth->SUPER::execute(@vars);
		my $dbh = $sth->{Database};
		Coro::AnyEvent::readable $dbh->{pg_socket} while !$dbh->pg_ready;
		$dbh->pg_result;
	}
}

1;
