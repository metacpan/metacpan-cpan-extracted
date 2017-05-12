################################################################################
#
# Apache::Voodoo::Debug::Handler
#
# Handles servicing debugging information requests
#
################################################################################
package Apache::Voodoo::Debug::Handler;

$VERSION = "3.0200";

use strict;
use warnings;

use DBI;
use Time::HiRes;
use JSON::DWIW;

use Apache::Voodoo::MP;
use Apache::Voodoo::Constants;

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{mp}        = Apache::Voodoo::MP->new();
	$self->{constants} = Apache::Voodoo::Constants->new();

	$self->{debug_root} = $self->{constants}->debug_path();

	warn "Voodoo Debugging Handler Starting...\n";

	$self->{template_dir} = $INC{"Apache/Voodoo/Debug/Handler.pm"};
	$self->{template_dir} =~ s/Handler.pm$/html/;

	$self->{handlers} = {
		map { $_ => 'handle_'.$_ }
		('profile','debug','return_data','session','template_conf','parameters','request')
	};

	$self->{static_files} = {
		"debug.css"     => "text/css",
		"debug.js"      => "application/x-javascript",
		"debug.png"     => "image/png",
		"error.png"     => "image/png",
		"exception.png" => "image/png",
		"info.png"      => "image/png",
		"minus.png"     => "image/png",
		"plus.png"      => "image/png",
		"spinner.gif"   => "image/gif",
		"table.png"     => "image/png",
		"trace.png"     => "image/png",
		"warn.png"      => "image/png"
	};

	$self->{json} = JSON::DWIW->new({bad_char_policy => 'convert', pretty => 1});;

	return $self;
}

sub handler {
	my $self = shift;
	my $r    = shift;

	$self->{mp}->set_request($r);

	# holds all vars associated with this page processing request
	my $uri = $self->{mp}->uri();
	$uri =~ s/^$self->{debug_root}//;
	$uri =~ s/^\///;

	if (defined($self->{static_files}->{$uri})) {
		# request for one of the static files.

		my $file = File::Spec->catfile($self->{template_dir},$uri);
		my $mtime = (stat($file))[9];

		# Handle "if not modified since" requests.
		$r->update_mtime($mtime);
		$r->set_last_modified;
		$r->meets_conditions;
		my $rc = $self->{mp}->if_modified_since($mtime);
		return $rc unless $rc == $self->{mp}->ok;

		# set the content type
		$self->{mp}->content_type($self->{static_files}->{$uri});

		# tell apache to send the underlying file
		$r->sendfile($file);

		return $self->{mp}->ok;
	}
	elsif (defined($self->{handlers}->{$uri})) {
		# request for an operation

		my $method = $self->{handlers}->{$uri};

		# parse the params
		my $params = $self->{mp}->parse_params(1);
		unless (ref($params)) {
			# something went boom
			return $self->display_host_error($params);
		}

		# connect to the debugging database
		my $dbh = DBI->connect_cached(@{$self->{constants}->debug_dbd()});
		unless ($dbh) {
			return $self->display_host_error("Can't connect to debugging database: ".DBI->errstr);
		}

		my $return;
		eval {
			$return = $self->$method($dbh,$params);
		};
		use Data::Dumper;
		warn Dumper $@;
		if ($@) {
			return $self->display_host_error("$@");
		}

		if (ref($return) eq "HASH") {
			$self->{mp}->content_type("application/json");
			$self->{mp}->print($self->{json}->to_json($return));
		}
		else {
			$self->{mp}->content_type("text/plain");
			$self->{mp}->print($return);
		}

		$self->{mp}->flush();

		return $self->{mp}->ok;
	}

	# not a request we handle
	return $self->{mp}->declined;
}

sub display_host_error {
	my $self  = shift;
	my $error = shift;

	$self->{'mp'}->content_type("text/html");
	$self->{'mp'}->print("<h2>The following error was encountered while processing this request:</h2>");
	$self->{'mp'}->print("<pre>$error</pre>");
	$self->{'mp'}->flush();

	return $self->{mp}->ok;
}

sub json_data {
	my $self = shift;
	my $type = shift;
	my $data = shift;

	if (ref($data)) {
		$data = $self->{json}->to_json($data);
	}
	elsif ($data !~ /^\s*[\[\{\"]/) {
		$data = '"'.$data.'"';
	}

	return '{"key":"'.$type.'","value":'.$data.'}';
}

sub json_error {
	my $self   = shift;
	my $errors = shift;

	my $return = {
		'success' => 'false',
		'errors'  => []
	};

	if (ref($errors) eq "HASH") {
		foreach my $key (keys %{$errors}) {
			push(@{$return->{errors}},{id => $key, msg => $errors->{$key}});
		}
	}
	else {
		push(@{$return->{errors}},{id => 'error', msg => $errors});
	}

	return $return;
}

sub json_true  { return $JSON::DWIW->true; }
sub json_false { return $JSON::DWIW->false; }

sub get_request_id {
	my $self = shift;
	my $dbh  = shift;
	my $id   = shift;

	unless ($id->{request_id} =~ /^\d+(\.\d*)?$/) {
		return "invalid request id";
	}

	unless ($id->{app_id} =~ /^[a-z]\w*$/i) {
		return "invalid application id";
	}

	unless ($id->{session_id} =~ /^[0-9a-z]+$/i) {
		return "invalid session id";
	}


	my $res = $dbh->selectcol_arrayref("
		SELECT id
		FROM   request
		WHERE
			request_timestamp = ? AND
			application       = ? AND
			session_id        = ?",undef,
		$id->{request_id},
		$id->{app_id},
		$id->{session_id});

	unless ($res->[0] > 0) {
		return "no such id";
	}

	return $res->[0];
}

sub select_data_by_id {
	my $self  = shift;
	my $dbh   = shift;
	my $table = shift;
	my $id    = shift;

	my $res = $dbh->selectall_arrayref("
		SELECT
			data
		FROM
			$table
		WHERE
			request_id = ?",undef,
		$id);

	return $res->[0]->[0];
}

sub simple_data {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;
	my $key    = shift;
	my $table  = shift;

	my $id = $self->get_request_id($dbh,$params);
	unless ($id =~ /^\d+$/) {
		return $self->json_error($id);
	}

	return $self->json_data(
		$key,
		$self->select_data_by_id($dbh,$table,$id)
	);
}

sub handle_template_conf {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;

	return $self->simple_data($dbh,$params,'vd_template_conf','template_conf');
}

sub handle_parameters {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;

	return $self->simple_data($dbh,$params,'vd_parameters','params');
}

sub handle_session {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;

	return $self->simple_data($dbh,$params,'vd_session','session');
}

sub handle_request {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;

	my $app_id     = $params->{'app_id'};
	my $session_id = $params->{'session_id'};
	my $request_id = $params->{'request_id'};

	my $return = [];
	if ($app_id     =~ /^[a-z]\w+/i   &&
		$session_id =~ /^[a-f0-9]+$/i &&
		$request_id =~ /^\d+\.\d+$/) {

		$return = $dbh->selectall_arrayref("
			SELECT
				request_timestamp AS request_id,
				url
			FROM
				request
			WHERE
				application = ? AND
				session_id  = ? AND
				request_timestamp >= ?
			ORDER BY
				id",{Slice => {}},
				$app_id,
				$session_id,
				$request_id);
	}

	return $self->json_data('vd_request',$return);
}

sub handle_return_data {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;

	my $id = $self->get_request_id($dbh,$params);
	unless ($id =~ /^\d+$/) {
		return $self->json_error($id);
	}

	my $res = $dbh->selectall_arrayref("
		SELECT
			handler,
			method,
			data
		FROM
			return_data
		WHERE
			request_id = ?
		ORDER BY
			seq",undef,
		$id);

	my $d = '[';
	foreach (@{$res}) {
		$d .= '["'.$_->[0].'-&gt;'.$_->[1].'",'.$_->[2].'],';
	}
	$d =~ s/,$//;
	$d .= ']';

	return $self->json_data('vd_return_data',$d);
}

sub handle_debug {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;

	my $id = $self->get_request_id($dbh,$params);
	unless ($id =~ /^\d+$/) {
		return $self->json_error($id);
	}

	my @levels;
	foreach (qw(debug info warn error exception table trace)) {
		if ($params->{$_} eq "1") {
			push(@levels,$_);
		}
	}

	my $query = "
		SELECT
			level,
			stack,
			data
		FROM
			debug
		WHERE
			request_id = ?";

	if (scalar(@levels)) {
		$query .= ' AND level IN (' . join(',',map { '?'} @levels) . ') ';
	}

	$query .= "
		ORDER BY
			seq";

	my $res = $dbh->selectall_arrayref($query,undef,$id,@levels);

	return $self->json_data('vd_debug',$self->_process_debug($params->{app_id},$res));
}

sub _process_debug {
	my $self   = shift;
	my $app_id = shift;
	my $data   = shift;

	my $debug = '[';
	foreach my $row (@{$data}) {
		$debug .= '{"level":"'.$row->[0].'"';
		$debug .= ',"stack":' .$row->[1];
		$debug .= ',"data":';
		if ($row->[2] =~ /^[\[\{\"]/) {
			$debug .= $row->[2];
		}
		else {
			$debug .= '"'.$row->[2].'"';
		}

		$debug .= '},';
	}
	$debug =~ s/,$//;
	$debug .= ']';

	return $debug;
}

sub handle_profile {
	my $self   = shift;
	my $dbh    = shift;
	my $params = shift;

	my $id = $self->get_request_id($dbh,$params);
	unless ($id =~ /^\d+$/) {
		return $self->json_error($id);
	}

	my $res = $dbh->selectall_arrayref("
		SELECT
			timestamp,
			data
		FROM
			profile
		WHERE
			request_id = ?
		ORDER BY
			timestamp",undef,
		$id);

	my $return;
	$return->{'key'} = 'vd_profile';

	my $last = $#{$res};
	if ($last > 0) {
		my $total_time = $res->[$last]->[0] - $res->[0]->[0];

		$return->{'value'} = [
			map {
				[
					sprintf("%.5f",    $res->[$_]->[0] - $res->[$_-1]->[0]),
					sprintf("%5.2f%%",($res->[$_]->[0] - $res->[$_-1]->[0])/$total_time*100),
					$res->[$_]->[1]
				]
			} (1 .. $last)
		];

		unshift(@{$return->{value}}, [
			sprintf("%.5f",$total_time),
			'percent',
			'message'
		]);
	}

	return $return;
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
