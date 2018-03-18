package Dwarf::Config;
use Dwarf::Pragma;
use Dwarf::Util qw/installed dwarf_log/;

use Dwarf::Accessor {
	ro => [qw/context is_data_path_installed is_data_dpath_installed/]
};

# Data::DPath サポート
sub _build_is_data_dpath_installed {
	my $self = shift;
	$self->{is_data_dpath_installed} ||= do {
		my $is_data_dpath_installed = 0;
		if (installed('Data::DPath')) {
			$is_data_dpath_installed = 1;
		}
		$is_data_dpath_installed;
	};
}

# Data::Path サポート
sub _build_is_data_path_installed {
	my $self = shift;
	$self->{is_data_path_installed} ||= do {
		my $is_data_path_installed = 0;
		if (installed('Data::Path')) {
			$is_data_path_installed = 1;
		}
		$is_data_path_installed;
	};
}

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	dwarf_log 'new Config';
	$self->init;
	return $self;
}

sub DESTROY {
	my $self = shift;
	dwarf_log 'DESTROY Config';
	delete $self->{context};
}

sub c { shift->context }

sub init {
	my $self = shift;
	$self->set($self->setup);
}

sub setup { return () }

sub get {
	my ($self, $key) = @_;

	if ($self->is_data_dpath_installed) {
		if ($key =~ /\//) {
			my $dpath = Data::DPath::Path->new(path => $key);
			return ($dpath->match($self))[0];
		}
	} elsif ($self->is_data_path_installed) {
		if ($key =~ /\//) {
			my $hpath = Data::Path->new($self);
			return $hpath->get($key);
		}
	}

	return $self->{$key};
}

sub set {
	my $self = shift;
	my $args = { @_ };

	while (my ($key, $value) = each %$args) {
		$self->{$key} = $value;
	}
}

1;
