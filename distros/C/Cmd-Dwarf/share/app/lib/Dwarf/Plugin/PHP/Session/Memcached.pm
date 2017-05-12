package PHP::Session::Memcached;
use strict;
use warnings;
use Digest::MD5  qw/md5_hex/;
use Dwarf::Util qw/load_class/;
use Encode qw/decode_utf8/;

sub _croak { require Carp; Carp::croak(@_) }
sub _carp  { require Carp; Carp::carp(@_) }

sub new {
    my($class, $sid, $opt) = @_;
	_croak "sid must be specified." unless defined $sid;

	my %default = (
		serialize_handler => 'PHP::Session::Serializer::PHP',
		create            => 0,
		auto_save         => 0,
	);
	$opt ||= {};

    my $self = bless {
		%default,
		%$opt,
		_sid     => $sid,
		_data    => {},
		_changed => 0,
    }, $class;

    $self->_validate_sid;
    $self->_parse_session;

    return $self;
}

sub id { shift->{_sid} }
sub memcached { shift->{memcached} }

sub serializer {
	my $self = shift;
	my $impl = $self->{serialize_handler};
	load_class($impl);
	return $impl->new;
}

sub get {
	my($self, $key) = @_;
	return $self->{_data}->{$key};
}

sub set {
	my($self, $key, $value) = @_;
	$self->{_changed}++;
	$self->{_data}->{$key} = $value;
}

sub unregister {
	my($self, $key) = @_;
	delete $self->{_data}->{$key};
}

sub unset {
	my $self = shift;
	$self->{_data} = {};
}

sub is_registered {
	my($self, $key) = @_;
	return exists $self->{_data}->{$key};
}

sub decode {
	my($self, $data) = @_;
	my $ret = eval { $self->serializer->decode($data) };
	if ($@) {
		warn "Something wrong in PHP::Session::Serializer::PHP";
		$ret = $self->serializer->decode(decode_utf8($data));
	}
	return $ret;
}

sub encode {
	my($self, $data) = @_;
	$self->serializer->encode($data);
}

sub save {
	my $self = shift;
	$self->memcached->set(
		$self->id,
		$self->encode($self->{_data})
	);
	$self->{_changed} = 0;	# init
}

sub destroy {
	my $self = shift;
	$self->memcached->delete($self->id);
}

sub DESTROY {
	my $self = shift;
	if ($self->{_changed}) {
		if ($self->{auto_save}) {
			$self->save;
		} else {
			_carp("PHP::Session::Memcached: some keys are changed but not saved.") if $^W;
		}
	}
}

sub _validate_sid {
	my $self = shift;
	$self->id =~ /^([0-9a-zA-Z]*)$/
		or _croak("Invalid session id: ", $self->id);
}

sub _parse_session {
	my $self = shift;
	my $cont = $self->_slurp_content;
	
	if (!$cont) {
		if ($self->{create}) {
			$self->{_data} = { __HTTP_Session_Info => 1 };
			$self->memcached->add(
				$self->id,
				$self->encode($self->{_data})
			);
		} else {
			_croak($self->id, ": $!");
		}
	}
	$self->{_data} = $self->decode($cont);
}

sub _slurp_content {
    my $self = shift;
    return $self->memcached->get($self->id);
}

package Dwarf::Plugin::PHP::Session::Memcached;
use strict;
use warnings;
use Dwarf::Util;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $memcached       = $conf->{memcached}       || undef;
	my $session_key     = $conf->{session_key}     || 'SessionID';
	my $param_name      = $conf->{param_name}      || $session_key;
	my $use_cookie      = $conf->{use_cookie}      || 1;
	my $cookie_path     = $conf->{cookie_path}     || '/';
	my $cookie_domain   = $conf->{cookie_domain}   || undef;
	my $cookie_expires  = $conf->{cookie_expires}  || undef;
	my $on_init         = $conf->{on_init}        || sub {};

	add_method($c, session => sub {
		my $self = shift;

		$self->{'dwarf.session'} ||= do {
			my $session_id = undef;

			if ($use_cookie) {
				my $cookie = $self->request->cookies->{$session_key};

				if (defined $cookie and $cookie ne '') {
					$session_id = $cookie;
				}
			}

			my $query_param = $self->request->param($param_name);

			if (defined $query_param and $query_param ne '') {
				$session_id = $query_param;
			}

			my $session = PHP::Session::Memcached->new($session_id, {
				memcached => $memcached || $self->memcached,
				create    => 1,
			});
			$on_init->($session);

			$session;
		}
	});

	return unless $use_cookie;

	$c->add_trigger('AFTER_DISPATCH' => sub {
		my ($self, $res) = @_;
		return unless exists $self->{'dwarf.session'};
		my $value = { value => $self->session->id };
		$value->{path} = $cookie_path if defined $cookie_path;
		$value->{domain} = $cookie_domain if defined $cookie_domain;
		$value->{expires} = time + $cookie_expires if defined $cookie_expires;
		$res->cookies({ $session_key, $value });
	});
}

1;
