package Dwarf::Plugin::HTTP::Session;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use Dwarf::Session;
use Dwarf::Session::State::Cookie;
use Dwarf::Session::Store::DBI;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $session_key         = $conf->{session_key}         || 'SESSION_ID';
	my $session_table       = $conf->{session_table}       || 'sessions';
	my $session_expires     = $conf->{session_expires}     || 3600;
	my $session_clean_thres = $conf->{session_clean_thres} || 0;
	my $param_name          = $conf->{param_name}          || 'session_id';
	my $cookie_path         = $conf->{cookie_path}         || '/';
	my $cookie_domain       = $conf->{cookie_domain}       || undef;
	my $cookie_expires      = $conf->{cookie_expires}      || undef;
	my $cookie_secure       = $conf->{cookie_secure}       // 0;
	my $cookie_httponly     = $conf->{cookie_httponly}     // 1;

	if ($cookie_expires) {
		$cookie_expires += time;
	}

	add_method($c, session => sub {
		my $self = shift;
		$self->{'dwarf.session'} ||= Dwarf::Session->new(
			state => Dwarf::Session::State::Cookie->new(
				param_name => $param_name,
				name       => $session_key,
				path       => $cookie_path,
				domain     => $cookie_domain,
				expires    => $cookie_expires,
				secure     => $cookie_secure,
				httponly   => $cookie_httponly,
			),
			store => Dwarf::Session::Store::DBI->new(
				dbh         => $self->dbh,
				sid_table   => $session_table,
				expires     => $session_expires,
				clean_thres => $session_clean_thres,
			),
			request => $self->request,
		);
	});

	add_method($c, refresh_session => sub {
		my ($self) = @_;
		my $session = $self->session;
		$session->regenerate_session_id(1);
	});

	add_method($c, delete_session => sub {
		my $self = shift;
		if (my $session = delete $self->{'dwarf.session'}) {
			$session->store->delete($session->session_id);
		}
	});

	add_method($c, store_params_on_session => sub {
		my $self = shift;
	});

	add_method($c, restore_params_from_session => sub {
		my $self = shift;
	});

	$c->add_trigger('AFTER_DISPATCH' => sub {
		my ($self, $res) = @_;
		if (my $session = $self->{'dwarf.session'}) {
			if (ref($session->store) eq 'Dwarf::Session::Store::DBI') {
				$session->store->cleanup; # Expire したセッションの掃除
			}
			$session->response_filter($res);
			$session->finalize();

			$res->header(P3P => 'CP="UNI CUR OUR"'); # IE のクッキー対策
		}
	});
}

1;
