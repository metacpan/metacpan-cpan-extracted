package Apache::Voodoo::Soap;

$VERSION = "3.0200";

use strict;
use warnings;

use SOAP::Transport::HTTP;
use Data::Structure::Util qw(unbless);


# FIXME: Hack to prefer my extended version of Pod::WSDL over the
# one on CPAN.  This will need to stay in place until either the
# author of Pod::WSDL replys or I release my own version.
my $PWSDL;
BEGIN {
	eval {
		require Pod::WSDL2;
		$PWSDL = 'Pod::WSDL2';
	};
	if ($@) {
		require Pod::WSDL;
		$PWSDL = 'Pod::WSDL';
	}
}

use MIME::Entity;

use Apache::Voodoo::MP;
use Apache::Voodoo::Engine;
use Apache::Voodoo::Exception;
use Exception::Class::DBI;

use Data::Dumper;

sub new {
	my $class = shift;

	my $self = {};
	bless $self,$class;

	$self->{'mp'}     = Apache::Voodoo::MP->new();
	$self->{'engine'} = Apache::Voodoo::Engine->new('mp' => $self->{'mp'});

	$self->{'soap'} = SOAP::Transport::HTTP::Apache->new();
	$self->{'soap'}->on_dispatch(
		sub {
			$self->{'run'}->{'method'} = $_[0]->dataof->name;
			return ("Apache/Voodoo/Soap","handle_request");
		}
	);

	$self->{'soap'}->dispatch_to($self,"handle_request");

	return $self;
}

sub handler {
	my $self = shift;
	my $r    = shift;

	$self->{'mp'}->set_request($r);
	$self->{'engine'}->set_request($r);

	eval {
		$self->{'engine'}->init_app();
	};
	if ($@) {
		warn "$@";
		return $self->{'mp'}->server_error();
	}

	my $return;
	if ($self->{'mp'}->is_get() && $r->unparsed_uri =~ /\?wsdl$/) {
		my $uri = $self->{'mp'}->uri();

		$uri =~ s/^\///;
		$uri =~ s/\/$//;

		# FIXME hack.  Shouldn't be looking in there to get this
		unless ($self->{'engine'}->_app->{'controllers'}->{$uri}) {
			return $self->{'mp'}->not_found();
		}

		my $m = ref($self->{'engine'}->_app->{'controllers'}->{$uri});
		if ($m eq "Apache::Voodoo::Loader::Dynamic") {
			$m = ref($self->{'engine'}->_app->{'controllers'}->{$uri}->{'object'});
		}
		# FIXME here ends the hackery

		my $wsdl;
		eval {
			# FIXME the other part of the Pod::WSDL version hack
			$wsdl = $PWSDL->new(
				source   => $m,
				location => $self->{'mp'}->server_url().$uri,
				pretty   => 1,
				withDocumentation => 1
			);
			$wsdl->targetNS($self->{'mp'}->server_url());
		};
		if ($@) {
			$self->{'mp'}->content_type('text/plain');
			my $s = "Error generating WSDL:\n\n$@";
			$s =~ s/\cJ/\n/g;
			$self->{'mp'}->print($s);
		}
		else {
			$self->{'mp'}->content_type('text/xml');
			$self->{'mp'}->print($wsdl->WSDL);
		}

		$self->{'mp'}->flush();
		$return = $self->{'mp'}->ok;
	}
	else {
		$return = $self->{'soap'}->handle($r);
	}

	$self->{'engine'}->status($self->{'status'});

	return $self->{'status'};
}

sub handle_request {
	my $self   = shift;
	my @params = @_;

	my $params = {};
	my $c=0;
	foreach (@params) {
		$_ = unbless($_) if $self->{'engine'}->{'config'}->{'soap_unbless'};
		if (ref($_) eq "HASH") {
			while (my ($k,$v) = each %{$_}) {
				$params->{$k} = $v;
			}
		}
		$params->{'ARGV'}->[$c] = $_;
		$c++;
	}

	my $uri      = $self->{'mp'}->uri();
	my $filename = $self->{'mp'}->filename();

	# if the SOAP endpoint happens to overlap with a directory name
	# libapr "helpfully" appends a / to the end of the uri and filenames.
	$uri      =~ s/\/$//;
	$filename =~ s/\/$//;

	$filename =~ s/\.tmpl$//;
	unless ($self->{'run'}->{'method'} eq 'handle') {
		$filename =~ s/([\w_]+)$/$self->{'run'}->{'method'}_$1/i;
		$uri      =~ s/([\w_]+)$/$self->{'run'}->{'method'}_$1/i;
	}

	unless (-e "$filename.tmpl" &&
	        -r "$filename.tmpl") {
		$self->{'status'} = $self->{'mp'}->not_found();
		$self->_client_fault($self->{'mp'}->not_found(),'No such service:'.$filename);
	};

	my $content;
	eval {
		$self->{'engine'}->begin_run();

		$content = $self->{'engine'}->execute_controllers($uri,$params);
	};
	if (my $e = Exception::Class->caught()) {
		if ($e->isa("Apache::Voodoo::Exception::Application::Redirect")) {
			$self->{'status'} = $self->{'mp'}->redirect;
			$self->_client_fault($self->{'mp'}->redirect,"Redirected",$e->target);
		}
		elsif ($e->isa("Apache::Voodoo::Exception::Application::DisplayError")) {
			# apparently OK doesn't return 200 anymore, it returns 0.  When used in conjunction
			# with a SOAP fault that lets the server default it to 500, which isn't what we want.
			# The server didn't have an internal error, we just didn't like what the client sent.
			$self->{'status'} = 200;
			$self->_client_fault($e->code, $e->error, $e->detail);
		}
		elsif ($e->isa("Apache::Voodoo::Exception::Application::AccessDenied")) {
			$self->{'status'} = $self->{'mp'}->forbidden;
			$self->_client_fault($self->{'mp'}->forbidden, $e->error, $e->detail);
		}
		elsif ($e->isa("Apache::Voodoo::Exception::Application::RawData")) {
			$self->{'status'} = $self->{'mp'}->ok;
			return {
				'error'        => 0,
				'success'      => 1,
				'rawdata'      => 1,
				'content-type' => $e->content_type,
				'headers'      => $e->headers,
				'data'         => $e->data
			};
		}
		elsif ($e->isa("Apache::Voodoo::Exception::Application::SessionTimeout")) {
			$self->{'status'} = $self->{'mp'}->ok;
			$self->_client_fault(700, $e->error, $e->target);
		}
		elsif ($e->isa("Apache::Voodoo::Exception::RunTime") && $self->{'engine'}->is_devel_mode()) {
			# Apache::Voodoo::Exception::RunTime
			# Apache::Voodoo::Exception::RunTime::BadCommand
			# Apache::Voodoo::Exception::RunTime::BadReturn
			$self->{'status'} = $self->{'mp'}->server_error;
			$self->_server_fault($self->{'mp'}->server_error, $e->error, Apache::Voodoo::Exception::parse_stack_trace($e->trace));
		}
		elsif ($e->isa("Exception::Class::DBI") && $self->{'engine'}->is_devel_mode()) {
			$self->{'status'} = $self->{'mp'}->server_error;
			$self->_server_fault($self->{'mp'}->server_error, $@->description, {
				"message" => $@->errstr,
				"package" => $@->package,
				"line"    => $@->line,
				"query"   => $@->statement
			});
		}
		elsif ($self->{'engine'}->is_devel_mode()) {
			$self->{'status'} = $self->{'mp'}->server_error;
			$self->_server_fault($self->{'mp'}->server_error, ref($e)?$e->error:"$e");
		}
		else {
			$self->{'status'} = $self->{'mp'}->server_error;
			$self->_server_fault($self->{'mp'}->server_error, "Internal Server Error");
		}
	}

	$self->{'status'} = $self->{'mp'}->ok;
	return $content;
}

sub _client_fault {
	my $self = shift;
	$self->_make_fault('Client',@_);
}

sub _server_fault {
	my $self = shift;
	$self->_make_fault('Server',@_);
}

sub _make_fault {
	my $self = shift;

	my ($t,$c,$s,$d) = @_;

	my %msg;
	if (defined($c)) {
		$msg{'faultcode'} = $t.'.'.$c;
	}
	else {
		$msg{'faultcode'} = $t;
	}

	warn($msg{'faultcode'});
	$msg{'faultstring'} = $s;
	$msg{'faultdetail'} = $d if (defined($d));

	die SOAP::Fault->new(%msg);
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
