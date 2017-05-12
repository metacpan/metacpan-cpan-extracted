package Dwarf::Plugin::Teng;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method load_class/;

sub init {
	my ($class, $c, $conf) = @_;
	$conf ||= {};

	my $db_class = $conf->{db_class} || $c->namespace . '::DB';
	my $default_db = $conf->{default_db} || 'master';

	my $connect_info = $c->config->get('db');

	$c->{'dwarf.db'} ||= {};

	add_method($c, db => sub {
		my ($self, $key) = @_;
		$key ||= $default_db;

		unless (defined $self->{'dwarf.db'}->{$key}) {
			$self->connect_db($db_class, $key, $connect_info->{$key});
		}

		return $self->{'dwarf.db'}->{$key};
	});

	add_method($c, connect_db => sub {
		my ($self, $db_class, $key, $connect_info) = @_;
		load_class($db_class);
		$self->{'dwarf.db'}->{$key} = $db_class->new({
			connect_info => [
				$connect_info->{dsn},
				$connect_info->{username},
				$connect_info->{password},
				$connect_info->{opts},
			],
		});
	});

	add_method($c, dbh => sub {
		my $self = shift;
		$self->db->dbh;
	});

	add_method($c, disconnect_db => sub {
		my $self = shift;
		my $db = $self->{'dwarf.db'};
		ref $db eq 'HASH' or return;
		for my $d (values %$db) {
			$d->disconnect if defined $d;
		}
		$self->{'dwarf.db'} = undef;
	});
}

1;
