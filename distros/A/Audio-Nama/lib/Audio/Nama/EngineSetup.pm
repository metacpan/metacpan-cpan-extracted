# ----------- Engine Setup and Teardown -----------

package Audio::Nama;
use Modern::Perl; use Carp;

sub reconfigure_engine {

	logsub("&reconfigure_engine");
	my $force = shift;

	# skip if command line option is set
	
	return if ($config->{opts}->{R} or $config->{disable_auto_reconfigure});
	update_jack_client_list();
	Audio::Nama::Engine::sync_action('configure');
}

sub request_setup { 
	my ($package, $filename, $line) = caller();
    logpkg(__FILE__,__LINE__,'debug',"reconfigure requested in file $filename:$line");
	$setup->{changed}++
} 

sub generate_setup {Audio::Nama::Engine::sync_action('setup') }

sub start_transport { 
	logsub("&start_transport");
	Audio::Nama::Engine::sync_action('start');

}

sub stop_transport { 

	logsub("&stop_transport"); 
	Audio::Nama::Engine::sync_action('stop');
}
	
1;
__END__