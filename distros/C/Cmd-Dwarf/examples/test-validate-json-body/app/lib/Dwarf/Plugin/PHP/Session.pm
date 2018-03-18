package Dwarf::Plugin::PHP::Session;
use strict;
use warnings;
use PHP::Session;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $session_key    = $conf->{session_key}    || 'PHPSESSID';
	my $param_name     = $conf->{param_name}     || $session_key;
	my $use_cookie     = $conf->{use_cookie}     || 1;
	my $cookie_path    = $conf->{cookie_path}    || '/';
	my $cookie_domain  = $conf->{cookie_domain}  || undef;
	my $cookie_expires = $conf->{cookie_expires} || undef;
	my $on_init        = $conf->{on_init}        || sub {};

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

			my $session = PHP::Session->new($session_id);
			$on_init->($session);

			$session;
		};
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
