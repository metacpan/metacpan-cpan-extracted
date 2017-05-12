package Apache::Voodoo::Debug::Native::common;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo");

use DBI;

sub set_dbh {
	my $self = shift;
	$self->{dbh} = shift;
}

sub get_dbh {
	return $_[0]->{dbh};
}

sub db_disconnect {
	my $self = shift;
	if ($self->{dbh}) {
		$self->{dbh}->disconnect;
	}
}

sub create_schema {
	my $self = shift;

	$self->_create_request();
	$self->_create_profile();
	$self->_create_debug();
	$self->_create_params();
	$self->_create_session();
	$self->_create_template_conf();
	$self->_create_return_data();

	$self->_create_version();
}

sub _create_version {
	my $self = shift;
	$self->{dbh}->do("CREATE TABLE version (version varchar(64) not null)")            || $self->db_error();
	$self->{dbh}->do("INSERT INTO version (version) VALUES(?)",undef,$self->{version}) || $self->db_error();
}

sub _create_request {
	my $self = shift;

	$self->{dbh}->do("CREATE TABLE request (
		id ".$self->_pkey_syntax.",
		request_timestamp varchar(64) not null,
		application       varchar(64) not null,
		session_id        varchar(64),
		url               varchar(255),
		status            varchar(128)
	)") || $self->db_error();

	$self->{dbh}->do("CREATE INDEX request_request_timestamp ON request(request_timestamp)") || $self->db_error();
	$self->{dbh}->do("CREATE INDEX request_session_id        ON request(session_id)")        || $self->db_error();
	$self->{dbh}->do("CREATE INDEX request_application       ON request(application)")       || $self->db_error();
	$self->{dbh}->do("CREATE INDEX request_url               ON request(url)")               || $self->db_error();
}

sub _get_request_id {
	my $self = shift;
	my $id   = shift;

	my $res = $self->{dbh}->selectcol_arrayref("
		SELECT
			id
		FROM
			request
		WHERE
			request_timestamp = ? AND
			application       = ?",undef,
		$id->{request_id},
		$id->{app_id}) || $self->db_error();

	return $res->[0];
}

sub handle_request {
	my $self = shift;
	my $data = shift;

	$self->{dbh}->do("
		INSERT INTO request (
			request_timestamp,
			application
		)
		VALUES (
			?,
			?
		)",undef,
		$data->{id}->{request_id},
		$data->{id}->{app_id}) || $self->db_error();
}

sub handle_url {
	my $self = shift;
	my $data = shift;

	$self->{dbh}->do("
		UPDATE request
		SET
			url = ?
		WHERE
			request_timestamp = ? AND
			application       = ?
		",undef,
		$data->{data},
		$data->{id}->{request_id},
		$data->{id}->{app_id}) || $self->db_error();
}

sub handle_session_id {
	my $self = shift;
	my $data = shift;

	$self->{dbh}->do("
		UPDATE request
		SET
			session_id = ?
		WHERE
			request_timestamp = ? AND
			application       = ?
		",undef,
		$data->{data},
		$data->{id}->{request_id},
		$data->{id}->{app_id}) || $self->db_error();
}

sub handle_status {
	my $self = shift;
	my $data = shift;

	$self->{dbh}->do("
		UPDATE request
		SET
			status = ?
		WHERE
			request_timestamp = ? AND
			application       = ?
		",undef,
		$data->{data},
		$data->{id}->{request_id},
		$data->{id}->{app_id}) || $self->db_error();
}

sub _create_profile {
	my $self = shift;

	$self->{dbh}->do("CREATE TABLE profile (
		request_id integer      not null,
		timestamp  varchar(64)  not null,
		data       varchar(255)
	)") || $self->db_error();

	$self->{dbh}->do("CREATE INDEX profile_request_id ON profile(request_id)") || $self->db_error();
	$self->{dbh}->do("CREATE INDEX profile_timestamp  ON profile(timestamp)")  || $self->db_error();
}

sub handle_profile {
	my $self = shift;
	my $data = shift;

	my $request_id = $self->_get_request_id($data->{id});
	unless ($request_id) {
		warn "no such request\n";
		return;
	}

	$self->{dbh}->do("
		INSERT INTO profile (
			request_id,
			timestamp,
			data
		)
		VALUES (
			?,
			?,
			?
		)",undef,
		$request_id,
		$data->{timestamp},
		$data->{data}) || $self->db_error();
}

sub _create_debug {
	my $self = shift;

	$self->{dbh}->do("CREATE TABLE debug (
		request_id integer          not null,
		seq        integer unsigned not null,
		level      varchar(64)      not null,
		stack      text             not null,
		data       text
	)") || $self->db_error();

	$self->{dbh}->do("CREATE INDEX debug_request_id ON debug(request_id)") || $self->db_error();
	$self->{dbh}->do("CREATE INDEX debug_seq        ON debug(seq)"       ) || $self->db_error();
	$self->{dbh}->do("CREATE INDEX debug_level      ON debug(level)"     ) || $self->db_error();
}

sub handle_debug {
	my $self = shift;
	my $data = shift;

	my $request_id = $self->_get_request_id($data->{id});
	unless ($request_id) {
		warn "no such request\n";
		return;
	}

	my $res = $self->{dbh}->selectcol_arrayref("
		SELECT
			MAX(seq)
		FROM
			debug
		WHERE request_id = ?",undef,$request_id) || $self->db_error();

	my $seq = (($res->[0])?$res->[0]:0) + 1;

	$data->{data} =~ s/^\s+//;
	$data->{data} =~ s/\s+$//;

	$self->{dbh}->do("
		INSERT INTO debug(
			request_id,
			seq,
			level,
			stack,
			data
		)
		VALUES (
			?,
			?,
			?,
			?,
			?
		)",undef,
		$request_id,
		$seq,
		$data->{level},
		$data->{stack},
		$data->{data}) || $self->db_error();
}

sub _create_params {
	my $self = shift;

	$self->{dbh}->do("CREATE TABLE params (
		request_id integer not null,
		data       text
	)") || $self->db_error();

	$self->{dbh}->do("CREATE INDEX params_request_id ON params(request_id)") || $self->db_error();
}

sub handle_params {
	my $self = shift;
	my $data = shift;

	my $request_id = $self->_get_request_id($data->{id});
	unless ($request_id) {
		warn "no such request\n";
		return;
	}

	$self->{dbh}->do("
		INSERT INTO params (
			request_id,
			data
		)
		VALUES (
			?,
			?
		)",undef,
		$request_id,
		$data->{data}) || $self->db_error();
}

sub _create_session {
	my $self = shift;

	$self->{dbh}->do("CREATE TABLE session (
		request_id integer not null,
		data       text
	)") || $self->db_error();

	$self->{dbh}->do("CREATE INDEX session_request_id ON session(request_id)") || $self->db_error();
}

sub handle_session {
	my $self = shift;
	my $data = shift;

	my $request_id = $self->_get_request_id($data->{id});
	unless ($request_id) {
		warn "no such request\n";
		return;
	}

	$self->{dbh}->do("
		INSERT INTO session (
			request_id,
			data
		)
		VALUES (
			?,
			?
		)",undef,
		$request_id,
		$data->{data}) || $self->db_error();
}

sub _create_template_conf {
	my $self = shift;

	$self->{dbh}->do("CREATE TABLE template_conf (
		request_id integer not null,
		data       text
	)") || $self->db_error();

	$self->{dbh}->do("CREATE INDEX tc_request_id ON template_conf(request_id)") || $self->db_error();
}

sub handle_template_conf {
	my $self = shift;
	my $data = shift;

	my $request_id = $self->_get_request_id($data->{id});
	unless ($request_id) {
		warn "no such request\n";
		return;
	}

	$self->{dbh}->do("
		INSERT INTO template_conf (
			request_id,
			data
		)
		VALUES (
			?,
			?
		)",undef,
		$request_id,
		$data->{data}) || $self->db_error();
}

sub _create_return_data {
	my $self = shift;

	$self->{dbh}->do("CREATE TABLE return_data (
		request_id integer      not null,
		seq        integer      not null,
		handler    varchar(128) not null,
		method     varchar(64)  not null,
		data       text
	)") || $self->db_error();

	$self->{dbh}->do("CREATE INDEX return_request_id ON return_data(request_id)") || $self->db_error();
	$self->{dbh}->do("CREATE INDEX return_seq        ON return_data(seq)")  || $self->db_error();
}

sub handle_return_data {
	my $self = shift;
	my $data = shift;

	my $request_id = $self->_get_request_id($data->{id});
	unless ($request_id) {
		warn "no such request\n";
		return;
	}

	my $res = $self->{dbh}->selectcol_arrayref("
		SELECT
			MAX(seq)
		FROM
			return_data
		WHERE request_id = ?",undef,$request_id) || $self->db_error();

	my $seq = (($res->[0])?$res->[0]:0) + 1;

	$self->{dbh}->do("
		INSERT INTO return_data (
			request_id,
			seq,
			handler,
			method,
			data
		)
		VALUES (
			?,
			?,
			?,
			?,
			?
		)",undef,
		$request_id,
		$seq,
		$data->{handler},
		$data->{method},
		$data->{data}) || $self->db_error();
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
