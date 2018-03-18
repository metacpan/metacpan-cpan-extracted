package Dwarf::Plugin::CGI::Session;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use CGI::Session;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $session_key     = $conf->{session_key}     || 'SESSION_ID';
	my $session_driver  = $conf->{session_driver}  || 'driver:PostgreSQL';
	my $session_opts    = $conf->{session_opts}    || { ColumnType => 'binary' };
	my $param_name      = $conf->{param_name}      || $session_key;
	my $use_cookie      = $conf->{use_cookie}      || 1;
	my $cookie_path     = $conf->{cookie_path}     || '/';
	my $cookie_domain   = $conf->{cookie_domain}   || undef;
	my $cookie_expires  = $conf->{cookie_expires}  || undef;
	my $cookie_httponly = $conf->{cookie_httponly} || 0;
	my $cookie_secure   = $conf->{cookie_secure}   || 0;
	my $on_init         = $conf->{on_init}         || sub {};

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

			my $session = CGI::Session->new(
				$session_driver,
				$session_id,
				{
					Handle => $self->dbh,
					%{ $session_opts }
				}
			) or die CGI::Session->errstr();
			$on_init->($session);
			$session->flush;

			$session;
		};
	});

	add_method($c, refresh_session => sub {
		my ($self, $will_copy) = @_;
		$will_copy = 1 unless defined $will_copy;

		my $session = $self->session;

		my $new_session = CGI::Session->new(
			$session_driver,
			undef,
			{
				Handle => $self->dbh,
				%{ $session_opts }
			}
		) or die CGI::Session->errstr();
		$on_init->($new_session);

		if ($will_copy) {
			my %params = %{ $session->dataref };
			for my $key (keys %params) {
				next if $key =~ m/^_SESSION_/;
				$new_session->param($key, $params{$key});
			}
			$new_session->flush;
		}

		$session->clear;
		$session->delete;
		$session->flush;

		$self->{'dwarf.session'} = $new_session;
	});

	add_method($c, delete_session => sub {
		my $self = shift;
		delete $self->{'dwarf.session'} if exists $self->{'dwarf.session'};
	});

	return unless $use_cookie;

	$c->add_trigger('AFTER_DISPATCH' => sub {
		my ($self, $res) = @_;

		return unless exists $self->{'dwarf.session'};
		my $value = { value => $self->session->id };
		$value->{path} = $cookie_path if defined $cookie_path;
		$value->{domain} = $cookie_domain if defined $cookie_domain;
		$value->{expires} = time + $cookie_expires if defined $cookie_expires;
		$value->{httponly} = 1 if $cookie_httponly;
		$value->{secure} = 1 if $cookie_secure;
		my $cookies = $res->cookies;
		$cookies->{$session_key} = $value;
		$res->cookies($cookies);
		$res->header(P3P => 'CP="UNI CUR OUR"'); # IE のクッキー対策
	});
}

1;
