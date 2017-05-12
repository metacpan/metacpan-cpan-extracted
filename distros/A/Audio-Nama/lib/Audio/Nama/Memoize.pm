# ------ Memoize subroutines ------
package Audio::Nama;
use Modern::Perl;
use Memoize qw(memoize unmemoize);

BEGIN { # OPTMIZATION
my @wav_functions = qw(
	get_versions 
	candidates 
	targets 
	versions 
	last 
);
my @track_functions = qw(
	dir 
	basename 
	full_path 
	group_last 
	last 
	current_wav 
	current_version 
	monitor_version 
	maybe_monitor 
	rec_status 
	region_start_time 
	region_end_time 
	playat_time 
	fancy_ops 
	input_path 
);
sub track_memoize { # before generate_setup
	return unless $config->{memoize};
	map{package Audio::Nama::Track; memoize($_) } @track_functions;
}
sub track_unmemoize { # after generate_setup
	return unless $config->{memoize};
	map{package Audio::Nama::Track; unmemoize ($_)} @track_functions;
}
sub restart_wav_memoize {
	return unless $config->{memoize};
	map{package Audio::Nama::Wav; unmemoize ($_); memoize($_) } 
		@wav_functions;
}
sub latency_memoize { 
	map{ memoize($_) } ('Audio::Nama::self_latency','Audio::Nama::latency_of');
}
sub latency_unmemoize {
	map{ unmemoize($_) } ('Audio::Nama::self_latency','Audio::Nama::latency_of');
}
sub latency_rememoize { latency_unmemoize(); latency_memoize() }

sub init_wav_memoize {
	return unless $config->{memoize};
	map{package Audio::Nama::Wav; memoize($_) } @wav_functions;
}
}
1;
__END__