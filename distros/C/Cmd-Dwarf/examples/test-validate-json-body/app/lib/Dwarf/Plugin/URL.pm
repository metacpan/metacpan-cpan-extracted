package Dwarf::Plugin::URL;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;

sub init {
	my ($class, $c, $conf) = @_;

	$conf //= {};
	$conf->{want_ssl_callback}        //= sub { my ($self, $host, $path) = @_; $self->redirect("https://$host$path") };
	$conf->{do_not_want_ssl_callback} //= sub { my ($self, $host, $path) = @_; $self->redirect("http://$host$path") },

	add_method($c, can_use_ssl => sub {
		my $self = shift;
		return $self->conf("ssl");
	});

	add_method($c, base_url => sub {
		my $self = shift;
		return $self->can_use_ssl ? $self->conf('url')->{ssl_base} : $self->conf('url')->{base};
	});

	add_method($c, is_ssl => sub {
		my $self = shift;
		return (($self->env->{HTTPS}//'') eq 'on' or ($self->env->{HTTP_X_FORWARDED_PROTO}//'') eq 'https') ? 1 : 0;
	});

	add_method($c, want_ssl => sub {
		my ($self, $path) = @_;
		$path //= $self->env->{REQUEST_URI}//'';
		if ($self->can_use_ssl and not $self->is_ssl) {
			my $host = $self->env->{HTTP_X_FORWARDED_HOST} || $self->env->{HTTP_HOST};
			$conf->{want_ssl_callback}->($self, $host, $path);
		}
	});

	add_method($c, do_not_want_ssl => sub {
		my ($self, $path) = @_;
		$path //= $self->env->{REQUEST_URI}//'';
		if ($self->can_use_ssl) {
			my $host = $self->env->{HTTP_X_FORWARDED_HOST} || $self->env->{HTTP_HOST};
			$conf->{do_not_want_ssl_callback}->($self, $host, $path);
		}
	});
}

1;
