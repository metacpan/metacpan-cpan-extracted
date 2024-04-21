package App::CPAN::Get::MetaCPAN;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Cpanel::JSON::XS;
use English;
use Error::Pure qw(err);
use IO::Barf qw(barf);
use LWP::UserAgent;
use Readonly;
use Scalar::Util qw(blessed);
use URI;

Readonly::Scalar our $FASTAPI => qw(https://fastapi.metacpan.org/v1/download_url/);

our $VERSION = 0.10;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# LWP::User agent object.
	$self->{'lwp_user_agent'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (defined $self->{'lwp_user_agent'}) {
		if (! blessed($self->{'lwp_user_agent'})
			|| ! $self->{'lwp_user_agent'}->isa('LWP::UserAgent')) {

			err "Parameter 'lwp_user_agent' must be a ".
				'LWP::UserAgent instance.';
		}
	} else {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new;
		$self->{'lwp_user_agent'}->agent(__PACKAGE__.'/'.$VERSION);
	}

	return $self;
}

sub search {
	my ($self, $args_hr) = @_;

	if (! defined $args_hr
		|| ref $args_hr ne 'HASH') {

		err 'Bad search options.';
	}
	if (! exists $args_hr->{'package'}) {
		err "Package doesn't present.";
	}

	my $uri = $self->_construct_uri($args_hr);
	my $content = eval {
		$self->_fetch($uri);
	};
	if ($EVAL_ERROR) {
		if ($EVAL_ERROR =~ m/^Cannot fetch/ms) {
			err "Module '$args_hr->{'package'}' doesn't exist.";
		} else {
			err $EVAL_ERROR;
		}
	}
	my $content_hr = decode_json($content);

	return $content_hr;
}

sub save {
	my ($self, $uri, $file) = @_;

	my $content = $self->_fetch($uri);

	barf($file, $content);

	return;
}

sub _construct_uri {
	my ($self, $args_hr) = @_;

	my %query = ();
	if ($args_hr->{'include_dev'}) {
		$query{'dev'} = 1;
	}
	if ($args_hr->{'version'}) {
		$query{'version'} = '== '.$args_hr->{'version'};
	} elsif ($args_hr->{'version_range'}) {
		$query{'version'} = $args_hr->{'version_range'};
	}

	my $uri = URI->new($FASTAPI.$args_hr->{'package'});
	$uri->query_form(each %query);

	return $uri->as_string;
}

sub _fetch {
	my ($self, $uri) = @_;

	my $res = $self->{'lwp_user_agent'}->get($uri);
	if (! $res->is_success) {
		my $err_hr = {
			'HTTP code' => $res->code,
			'HTTP message' => $res->message,
		};
		if ($res->is_client_error) {
			err "Cannot fetch '$uri' URI.", %{$err_hr};
		} elsif ($res->is_server_error) {
			err "Cannot connect to CPAN server.", %{$err_hr};
		} else {
			err "Cannot fetch '$uri'.", %{$err_hr};
		}
	}

	return $res->content;
}

1;
