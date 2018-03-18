package Dwarf::Plugin::AnyEvent::Redis;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use AnyEvent::Redis;

sub init {
	my ($class, $c, $opt) = @_;
	$opt ||= {};
	$opt->{default_connection} ||= 'master';
	$opt->{on_error}           ||= sub { warn @_ };
	$opt->{on_cleanup}         ||= sub { warn "Connection closed: @_" };

	add_method($c, redis => sub {
		my ($self, $key) = @_;
		$key ||= $opt->{default_connection};

		my $conf = $self->conf('redis')
			or return;

		$self->{'dwarf.redis'} ||= do {
			my $repo;
			for my $key (keys %{ $conf }) {
				$repo->{$key} = AnyEvent::Redis->new({
					host     => $conf->{$key}->{host},
					port     => $conf->{$key}->{port},
					encoding => $conf->{$key}->{encoding} || 'utf8',
				});
				$repo->{$key}->select($conf->{$key}->{dbid} // 0);
			}
			$repo;
		};

		my $redis = $self->{'dwarf.redis'};
		return $redis->{$key} if exists $redis->{$key};
		return;
	});
}

1;