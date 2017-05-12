################################################################################
#
# Apache::Voodoo::Debug - handles operations associated with debugging output.
#
# This object is used by Voodoo internally to handling various types of debugging
# information and to produce end user display of that information.  End users
# never interact with this module directly, instead they use the methods from
# the Apache::Voodoo base class.
#
################################################################################
package Apache::Voodoo::Debug::Native;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Debug::Common");

use Apache::Voodoo::Constants;

use DBI;
use HTML::Template;
use JSON::DWIW;

sub new {
	my $class = shift;

	my $id   = shift;
	my $conf = shift;

	my $self = {};
	bless($self,$class);

	$self->{id}->{app_id} = $id;

	my $ac = Apache::Voodoo::Constants->new();

	my @flags = qw(debug info warn error exception table trace);
	my @flag2 = qw(profile params template_conf return_data session);

	$self->{enabled} = 0;
	if ($conf eq "1" || (ref($conf) eq "HASH" && $conf->{all})) {
		foreach (@flags,@flag2) {
			$self->{enable}->{$_} = 1;
		}
		$self->{enable}->{anydebug} = 1;
		$self->{enabled} = 1;
	}
	elsif (ref($conf) eq "HASH") {
		foreach (@flags) {
			if ($conf->{$_}) {
				$self->{enable}->{$_} = 1;
				$self->{enable}->{anydebug} = 1;
				$self->{enabled} = 1;
			}
		}
		foreach (@flag2) {
			if ($conf->{$_}) {
				$self->{enable}->{$_} = 1;
				$self->{enabled} = 1;
			}
		}
	}

	if ($self->{enabled}) {
		my $file = $INC{"Apache/Voodoo/Constants.pm"};
		$file =~ s/Constants.pm$/Debug\/html\/debug.tmpl/;

		$self->{template} = HTML::Template->new(
			'filename'          => $file,
			'die_on_bad_params' => 0,
			'global_vars'       => 1,
			'loop_context_vars' => 1
		);

		$self->{template}->param(
			debug_root => $ac->debug_path(),
			app_id     => $self->{id}->{app_id}
		);

		$self->{json} = JSON::DWIW->new({bad_char_policy => 'convert', pretty => 1});

		$self->{db_info} = $ac->debug_dbd();
		my $dbh;
		eval {
			$dbh = DBI->connect(@{$self->{db_info}});
		};
		if ($@) {
			warn "Debugging infomation will be lost: $@";
			$self->{enabled} = 0;
			return;
		}

		# From the DBI docs.  This will give use the database server name
		my $db_type = $dbh->get_info(17);

		eval {
			require "Apache/Voodoo/Debug/Native/$db_type.pm";
			my $class = 'Apache::Voodoo::Debug::Native::'.$db_type;
			$self->{db} = $class->new();
		};
		if ($@) {
			die "$db_type is not supported: $@";
		}

		$self->{db}->init_db($dbh,$ac);
	}

	# we always send this since is fundamental to identifying the request chain
	# regardless of what other info we log
	$self->{enable}->{url}        = 1;
	$self->{enable}->{status}     = 1;
	$self->{enable}->{session_id} = 1;

	return $self;
}

sub init {
	my $self = shift;
	my $mp   = shift;

	return unless $self->{enabled};

	$self->{id}->{request_id} = $mp->request_id();

	$self->{db}->set_dbh(DBI->connect(@{$self->{db_info}}) || die DBI->errstr);

	$self->_write({
		type => 'request',
		id   => $self->{'id'}
	});

	$self->{template}->param(request_id => $self->{id}->{request_id});
}

sub enabled {
	return $_[0]->{enabled};
}

sub shutdown {
	$_[0]->{db}->db_disconnect();
	return;
}

sub debug     { my $self = shift; $self->_debug('debug',    @_); }
sub info      { my $self = shift; $self->_debug('info',     @_); }
sub warn      { my $self = shift; $self->_debug('warn',     @_); }
sub error     { my $self = shift; $self->_debug('error',    @_); }
sub exception { my $self = shift; $self->_debug('exception',@_); }
sub trace     { my $self = shift; $self->_debug('trace',    @_); }
sub table     { my $self = shift; $self->_debug('table',    @_); }

sub _debug {
	my $self = shift;
	my $type = shift;

	return unless $self->{'enable'}->{$type};

	my $data;
	if (scalar(@_) > 1 || ref($_[0])) {
		# if there's more than one item, or the item we have is a reference
		# then we need to serialize it.
		$data = $self->_encode(@_);
	}
	else {
		# simple scalar can be logged as is.
		$data = $_[0];
	}

	my $full = ($type =~ /(exception|trace)/)?1:0;

	$self->_write({
		type  => 'debug',
		id    => $self->{id},
		level => $type,
		stack => $self->_encode([$self->stack_trace($full)]),
		data  => $data
	});
}

sub mark {
	my $self = shift;

	return unless $self->{'enable'}->{'profile'};

	$self->_write({
		type      => 'profile',
		id        => $self->{id},
		timestamp => shift,
		data      => shift
	});
}

sub return_data {
	my $self = shift;

	return unless $self->{'enable'}->{'return_data'};

	$self->_write({
		type    => 'return_data',
		id      => $self->{id},
		handler => shift,
		method  => shift,
		data    => $self->_encode(shift)
	});
}


# these all behave the same way.  With the execption of session_id which
# also inserts it into the underlying template.
sub url           { my $self = shift; $self->_log('url',           @_); }
sub status        { my $self = shift; $self->_log('status',        @_); }
sub params        { my $self = shift; $self->_log('params',        @_); }
sub template_conf { my $self = shift; $self->_log('template_conf', @_); }
sub session       { my $self = shift; $self->_log('session',       @_); }

sub session_id {
	my $self = shift;
	my $id   = shift;

	$self->{template}->param(session_id => $id);
	$self->_log('session_id',$id);
}

sub _log {
	my $self = shift;
	my $type = shift;

	return unless $self->{'enable'}->{$type};

	my $data;
	if (scalar(@_) > 1 || ref($_[0])) {
		# if there's more than one item, or the item we have is a reference
		# then we need to serialize it.
		$data = $self->_encode(@_);
	}
	else {
		# simple scalar can be logged as is.
		$data = $_[0];
	}

	$self->_write({
		type => $type,
		id   => $self->{id},
		data => $data
	});
}

sub _encode {
	my $self = shift;

	my $j;
	if (scalar(@_) > 1) {
		$j = $self->{json}->to_json(\@_);
	}
	else {
		$j = $self->{json}->to_json($_[0]);
	}

	return $j;
}


sub _write {
	my $self = shift;
	my $data = shift;

	my $handler = 'handle_'.$data->{'type'};

	if ($self->{db}->can($handler)) {
		$self->{db}->$handler($data);
	}
}

sub finalize {
	my $self = shift;

	return () unless $self->{enabled};

	foreach (keys %{$self->{'enable'}}) {
		$self->{template}->param('enable_'.$_ => $self->{'enable'}->{$_});
	}

	return (_DEBUG_ => $self->{template}->output());
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
