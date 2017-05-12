use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Session;
use Storable qw(thaw freeze);
use HTML::Tested::Seal;

sub access_handler($$) {
	my ($class, $r) = @_;
	my $session = $class->begin($r);
	$r->pnotes("SWITSession", $session);
	return Apache2::Const::OK();
}

sub begin {
	my ($class, $r) = @_;
	my %args = (_request => $r);
	my %cookies = Apache2::Cookie->fetch($r);
	$args{session_value} = $cookies{$class->cookie_name}->value
		if $cookies{$class->cookie_name};
	my $self = $class->new(%args);
	$self->read_stash;
	return $self;
}

sub request { return shift()->{_request}; }

sub end {
	my $self = shift;
	$self->write_stash;
	my $cookie = Apache2::Cookie->new($self->{_request}, 
			'-name' => $self->cookie_name,
			'-value' => $self->session_value);
	$cookie->path($self->{_request}->dir_config("SWITRootLocation") . ";HttpOnly");
	$cookie->bake($self->{_request});
}

sub new {
	my ($class, %args) = @_;
	return bless(\%args, $class);
}

sub _get {
	my ($self, $name, $val) = @_;
	return $self->{_stash}->{$name};
}

sub _delete_children {
	my ($self, $name) = @_;
	for my $d (@{ $self->_get_args($name)->{children} || [] }) {
		my $f = "delete_$d";
		$self->$f;
	}
}

sub _set {
	my ($self, $name, $val) = @_;
	$self->{_stash}->{$name} = $val;
	$self->_delete_children($name);
}

sub _delete {
	my ($self, $name) = @_;
	my $res = delete $self->{_stash}->{$name};
	$self->_delete_children($name);
	return $res;
}

sub add_class_dbi_var {
	my ($class, $var, $dbi_class) = @_;
	$class->add_var($var, inflate => sub {
		return $dbi_class->retrieve(shift());
	}, deflate => sub { return shift()->id });
}

sub _get_args {
	my ($self, $name) = @_;
	my $p_args = "$name\_args";
	return $self->$p_args;
}

sub add_var {
	my ($class, $name, %args) = @_;
	no strict 'refs';
	*{ "$class\::get_$name" } = sub {
		return shift()->_get($name, @_);
	};
	*{ "$class\::set_$name" } = sub {
		return shift()->_set($name, @_);
	};
	*{ "$class\::delete_$name" } = sub {
		return shift()->_delete($name, @_);
	};
	*{ "$class\::$name\_args" } = sub { return \%args; };

	$args{children} = [] unless $args{children};

	for my $d (@{ $args{depends_on} || [] }) {
		push @{ $class->_get_args($d)->{children} }, $name;
	}
}

sub session_value { return shift()->{session_value}; }

sub write_stash {
	my $self = shift;
	my %s;
	while (my ($n, $v) = each %{ $self->{_stash} }) {
		my $in = $self->_get_args($n)->{deflate};
		$s{$n} = $in ? $in->($v) : $v;
	}
	$self->{session_value} = HTML::Tested::Seal->instance->encrypt(
					freeze(\%s));
}

sub _thaw {
	my $v = shift->session_value or return {};
	my $res = HTML::Tested::Seal->instance->decrypt($v) or return {};
	return thaw($res);
}

sub read_stash {
	my $self = shift;
	my $s = $self->_thaw;
	my %stash;
	while (my ($n, $v) = each %$s) {
		my $d = $self->_get_args($n)->{inflate};
		$stash{$n} = $d ? $d->($v) : $v;
	}
	$self->{_stash} = \%stash;
}

sub swit_startup {}

1;
