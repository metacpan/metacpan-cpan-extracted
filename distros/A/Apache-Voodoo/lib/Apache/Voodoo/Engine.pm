package Apache::Voodoo::Engine;

$VERSION = "3.0200";

use strict;
use warnings;

use DBI;
use File::Spec;
use Time::HiRes;

use Scalar::Util 'blessed';

use Apache::Voodoo::Constants;
use Apache::Voodoo::Application;
use Apache::Voodoo::Exception;

use Exception::Class::DBI;

# Debugging object.  I don't like using an 'our' variable, but it is just too much
# of a pain to pass this thing around to everywhere it needs to go. So, I just tell
# myself that this is STDERR on god's own steroids so I can sleep at night.
our $debug;

our $i_am_a_singleton;

sub new {
	my $class = shift;
	my %opts  = @_;

	if (ref($i_am_a_singleton)) {
		return $i_am_a_singleton;
	}

	my $self = {};
	bless $self, $class;

	$self->{'mp'} = $opts{'mp'};

	$self->{'constants'} = $opts{'constants'} || Apache::Voodoo::Constants->new();

	$self->restart($opts{'only_start'});

	# Setup signal handler for die so that all deaths become exception objects
	# This way we can get a stack trace from where the death occurred, not where it was caught.
	$SIG{__DIE__} = sub {
		if (blessed($_[0]) && $_[0]->can("rethrow")) {
			# Already died using an exception class, just pass it up the chain
			$_[0]->rethrow;
		}
		else {
			Apache::Voodoo::Exception::RunTime->throw(error => join("\n", @_));
		}
	};

	$i_am_a_singleton = $self;

	return $self;
}

sub valid_app {
	my $self   = shift;
	my $app_id = shift;

	return (defined($self->{'apps'}->{$app_id}))?1:0;
}

sub get_apps {
	my $self = shift;

	return keys %{$self->{'apps'}};
}

sub is_devel_mode {
	my $self = shift;
	return ($self->_app->config->{'devel_mode'})?1:0;
}

sub set_request {
	my $self = shift;
	$self->{'mp'}->set_request(shift);
}

sub init_app {
	my $self = shift;

	my $id = shift || $self->{'mp'}->get_app_id();

	$self->{'app_id'} = $id;

	unless (defined($id)) {
		Apache::Voodoo::Exception::Application->throw(
			"PerlSetVar ID not present in configuration.  Giving up."
		);
	}

	# app exists?
	unless ($self->valid_app($id)) {
		Apache::Voodoo::Exception::Application->throw(
			"Application id '$id' unknown. Valid ids are: ".join(",",$self->get_apps())
		);
	}

	if ($self->_app->{'dynamic_loading'}) {
		$self->_app->refresh();
	}

	if ($self->_app->{'DEAD'}) {
		Apache::Voodoo::Exception::Application->throw("Application $id failed to load.");
	}


	return 1;
}

sub begin_run {
	my $self = shift;

	$self->{'mp'}->register_cleanup($self,\&finish);

	# setup debugging
	$debug = $self->_app->{'debug_handler'};
	$debug->init($self->{'mp'});
	$debug->mark(Time::HiRes::time,"START");

	$self->{'dbh'} = $self->attach_db();

	$self->{'session_handler'} = $self->attach_session();
	$self->{'session'} = $self->{'session_handler'}->session;

	$debug->session_id($self->{'session_handler'}->{'id'});
	$debug->mark(Time::HiRes::time,'Session Attachment');


	$debug->mark(Time::HiRes::time,'DB Connect');

	return 1;
}

sub attach_db {
	my $self = shift;

	my $db = undef;
	foreach (@{$self->_app->databases}) {
		eval {
			$db = DBI->connect_cached(@{$_});
		};
		last if $db;

		Apache::Voodoo::Exception::DBIConnect->throw($DBI::errstr);
	}

	return $db;
}

sub parse_params {
	my $self = shift;

	my $params = $self->{mp}->parse_params($self->_app->config->{'upload_size_max'});
	unless (ref($params)) {
		Apache::Voodoo::Exception::ParamParse->throw($params);
	}
	$debug->mark(Time::HiRes::time,"Parameter parsing");
	$debug->params($params);

	return $params;
}

sub status {
	my $self   = shift;
	my $status = shift;

	if (defined($debug)) {
		$debug->status($status);
		$debug->session($self->{'session'});
	}

	if (defined($self->_app) && defined($self->{'session_handler'})) {
		if ($self->{'p'}->{'uri'} =~ /\/?logout(_[^\/]+)?$/) {
			$self->{'mp'}->set_cookie($self->_app->config->{'cookie_name'},'!','now');
			$self->{'session_handler'}->destroy();
		}
		else {
			$self->{'session_handler'}->disconnect();
		}
		$debug->mark(Time::HiRes::time,'Session detachment');
	}
}

sub finish {
	my $self = shift;

	$debug->mark(Time::HiRes::time,'Cleaning up.');

	delete $self->{'app_id'};
	delete $self->{'session_handler'};
	delete $self->{'session'};
	delete $self->{'p'};
	delete $self->{'dbh'};

	if (defined($debug)) {
		$debug->mark(Time::HiRes::time,'END');
		$debug->shutdown();
	}
}

sub attach_session {
	my $self = shift;

	my $conf = $self->_app->config;

	my $session_id = $self->{'mp'}->get_cookie($conf->{'cookie_name'});

	my $session = $self->_app->{'session_handler'}->attach($session_id,$self->{'dbh'});

	if (!defined($session_id) || $session->id() ne $session_id) {
		# This is a new session, or there was an old cookie from a previous sesion,
		$self->{'mp'}->set_cookie($conf->{'cookie_name'},$session->id());
	}
	elsif ($session->has_expired($conf->{'session_timeout'})) {
		# the session has expired
		$self->{'mp'}->set_cookie($conf->{'cookie_name'},'!','now');
		$session->destroy;

		Apache::Voodoo::Exception::Application::SessionTimeout->throw(
			target  => $self->_adjust_url("/timeout"),
			error => "Session has expired"
		);
	}

	# update the session timer
	$session->touch();

	return $session;
}

sub history_capture {
	my $self   = shift;
	my $uri    = shift;
	my $params = shift;

	my $session = $self->{'session'};

	$uri = "/".$uri if $uri !~ /^\//;

	# don't put the login page in the referrer queue
	return if $uri eq "/login";

	if (!defined($session->{'history'}) ||
		$session->{'history'}->[0]->{'uri'} ne $uri) {

		# queue is empty or this is a new page
		unshift(@{$session->{'history'}}, {'uri' => $uri, 'params' => join("&",map { $_."=".$params->{$_} } keys %{$params})});
	}
	else {
		# re-entrant call to page, update the params
		$session->{'history'}->[0]->{'params'} = join("&",map { $_."=".$params->{$_} } keys %{$params});
	}

	if (scalar(@{$session->{'history'}}) > 30) {
		# keep the queue at 10 items
		pop @{$session->{'history'}};
	}

	$debug->mark(Time::HiRes::time,"history capture");
}

sub get_model {
	my $self   = shift;

	my $app_id = shift;
	my $model  = shift;

	unless ($self->valid_app($app_id)) {
		Apache::Voodoo::Exception::Application->throw(
			"Application id '$app_id' unknown. Valid ids are: ".join(",",$self->get_apps())
		);
	}

	return $self->{'apps'}->{$app_id}->{'models'}->{$model};
}

sub execute_controllers {
	my $self   = shift;
	my $uri    = shift;
	my $params = shift;

	$uri =~ s/^\///;
	$debug->url($uri);

	my $app = $self->_app;

	my $template_conf = $app->resolve_conf_section($uri);

	$debug->mark(Time::HiRes::time,"config section resolution");
	$debug->template_conf($template_conf);

	$self->{'p'} = {
		"dbh"           => $self->{'dbh'},
		"params"        => $params,
		"session"       => $self->{'session'},
		"template_conf" => $template_conf,
		"mp"            => $self->{'mp'},
		"uri"           => $uri,

		# these are deprecated.  In the future get them from $p->{mp} or $p->{config}
		"document_root" => $self->_app->config->{'template_dir'},
		"dir_config"    => $self->{'mp'}->dir_config,
		"user-agent"    => $self->{'mp'}->header_in('User-Agent'),
		"r"             => $self->{'mp'}->{'r'},
		"themes"        => $self->_app->config->{'themes'}
	};

	my $template_params;

	# call each of the pre_include modules followed by our page specific module followed by our post_includes
	foreach my $c (
		( map { [ $_, "handle"] } split(/\s*,\s*/o, $template_conf->{'pre_include'}  ||"") ),
		$app->map_uri($uri),
		( map { [ $_, "handle"] } split(/\s*,\s*/o, $template_conf->{'post_include'} ||"") )
		) {

		if (defined($app->{'controllers'}->{$c->[0]}) && $app->{'controllers'}->{$c->[0]}->can($c->[1])) {
			my $obj    = $app->{'controllers'}->{$c->[0]};
			my $method = $c->[1];

			my $return;
			eval {
				$return = $obj->$method($self->{'p'});
			};

			$debug->mark(Time::HiRes::time,"handler for ".$c->[0]." ".$c->[1]);
			$debug->return_data($c->[0],$c->[1],$return);

			if (my $e = Exception::Class->caught()) {
				if (ref($e) =~ /(AccessDenied|Redirect|DisplayError)$/) {
					$e->{'target'} = $self->_adjust_url($e->target);
					$e->rethrow();
				}
				elsif (ref($e)) {
					$e->rethrow();
				}
				else {
					Apache::Voodoo::Exception::RunTime->throw("$@");
				}
			}

			if (!defined($template_params) || !ref($return)) {
				# first overwrites empty, or scalar overwrites previous
				$template_params = $return;
			}
			elsif (ref($return) eq "HASH" && ref($template_params) eq "HASH") {
				# merge two hashes
				foreach my $k ( keys %{$return}) {
					$template_params->{$k} = $return->{$k};
				}
				$debug->mark(Time::HiRes::time,"result packing");
			}
			elsif (ref($return) eq "ARRAY" && ref($template_params) eq "ARRAY") {
				# merge two arrays
				push(@{$template_params},@{$return});
			}
			else {
				# eep.  can't merge.
				Apache::Voodoo::Exception::RunTime::BadReturn->throw(
					module  => $c->[0],
					method  => $c->[1],
					data    => $return
				);
			}

			last if $self->{'p'}->{'_stop_chain_'};
		}
	}

	return $template_params;
}

sub execute_view {
	my $self    = shift;
	my $content = shift;

	my $view;
	if (defined($self->{'p'}->{'_view_'}) &&
		defined($self->_app->{'views'}->{$self->{'p'}->{'_view_'}})) {

		$view = $self->_app->{'views'}->{$self->{'p'}->{'_view_'}};
	}
	elsif (defined($self->{'p'}->{'template_conf'}->{'default_view'}) &&
	       defined($self->_app->{'views'}->{$self->{'p'}->{'template_conf'}->{'default_view'}})) {

		$view = $self->_app->{'views'}->{$self->{'p'}->{'template_conf'}->{'default_view'}};
	}
	else {
		$view = $self->_app->{'views'}->{'HTML'};
	}

	$view->begin($self->{'p'});

	if (blessed($content) && $content->can('rethrow')) {
		$view->exception($content);
	}
	else {
		# pack up the params. note the presidence: module overrides template_conf
		$view->params($self->{'p'}->{'template_conf'});
		$view->params($content);
	}

	# add any params from the debugging handlers
	$view->params($debug->finalize());

	return $view;
}

sub restart {
	my $self = shift;
	my $app  = shift;

	# wipe / initialize host information
	$self->{'apps'} = {};

	warn "Voodoo starting...\n";

	my $cf_name      = $self->{'constants'}->conf_file();
	my $install_path = $self->{'constants'}->install_path();

	warn "Scanning: $install_path\n";

	unless (opendir(DIR,$install_path)) {
		warn "Can't open dir: $!\n";
		return;
	}

	foreach my $id (readdir(DIR)) {
		next if (defined($app) && $id ne $app);

		next unless $id =~ /^[a-z]\w*$/i;
		my $fp = File::Spec->catfile($install_path,$id,$cf_name);
		next unless -f $fp;
		next unless -r $fp;

		warn "starting application $id\n";

		my $app = Apache::Voodoo::Application->new($id,$self->{'constants'});

		my $dbh;
		# check to see if we can get a database connection
		foreach (@{$app->databases}) {
			eval {
				$dbh = DBI->connect(@{$_});
			};
			last if $dbh;

			warn "========================================================\n";
			warn "DB CONNECT FAILED FOR $id\n";
			warn $DBI::errstr."\n";
			warn "========================================================\n";
		}

		if ($dbh) {
			$dbh->disconnect;
		}

		$self->{'apps'}->{$id} = $app;

		# notifiy of start errors
		$self->{'apps'}->{$id}->{"DEAD"} = 0;

		if ($app->{'errors'}) {
			warn "$id has ".$app->{'errors'}." errors\n";
			if ($app->{'halt_on_errors'}) {
				warn " (dropping this site)\n";

				$self->{'apps'}->{$app->{'id'}}->{"DEAD"} = 1;

				return;
			}
			else {
				warn " (loading anyway)\n";
			}
		}
	}
	closedir(DIR);

	foreach (values %{$self->{'apps'}}) {
		$_->bootstrapped();
	}
}

sub _adjust_url {
	my $self = shift;
	my $uri  = shift;

	my $sr = $self->{'mp'}->site_root();
	if ($sr ne "/" && $uri =~ /^\//o) {
		return $sr.$uri;
	}
	else {
		return $uri;
	}

}

sub _app {
	my $self = shift;

	return $self->{'apps'}->{$self->{'app_id'}};

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
