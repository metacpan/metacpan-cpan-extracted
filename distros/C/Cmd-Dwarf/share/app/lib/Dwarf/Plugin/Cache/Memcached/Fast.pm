package Dwarf::Plugin::Cache::Memcached::Fast;
use Dwarf::Pragma;
use Dwarf::Util qw/add_method/;
use Cache::Memcached::Fast;

sub init {
	my ($class, $c, $opt) = @_;
	$opt ||= {};
	$opt->{compress_threshold} ||= 100_000;
	$opt->{default_memcached}  ||= 'page';

	add_method($c, memcached => sub {
		my ($self, $key) = @_;
		$key ||= $opt->{default_memcached};

		my $conf = $self->conf('memcached')
			or return;

		$self->{'dwarf.memcached'} ||= do {
			my $repo;
			for my $key (keys %{ $conf }) {
				$repo->{$key} = Cache::Memcached::Fast->new({
					servers            => [ { address => $conf->{$key}->{server} } ],
					namespace          => $conf->{$key}->{namespace},
					compress_threshold => $opt->{compress_threshold},
				});
			}
			$repo;
		};

		my $memcached = $self->{'dwarf.memcached'};
		return $memcached->{$key} if exists $memcached->{$key};
		return;
	});
}

1;