package Manager;
use Moose;
with qw(MooseX::Workers);

BEGIN { 
	$ENV{CATALYST_ENGINE} = 'Stomp';
	require Catalyst::Engine::Stomp;
}  

use FindBin;
use lib "$FindBin::Bin/../lib";

sub run {
	my $self = shift;
	for my $i (1..4) {
		$self->spawn( sub { 
				      require StompTestApp;
				      StompTestApp->run();
			      } );
	}
        POE::Kernel->run();
}

# Implement our Interface
sub worker_manager_start { warn 'started worker manager' }
sub worker_manager_stop  { warn 'stopped worker manager' }
sub max_workers_reached  { warn 'maximum worker count reached' }

sub worker_stdout  { shift; warn join ' ', @_; }
sub worker_stderr  { shift; warn join ' ', @_; }
sub worker_error   { shift; warn join ' ', @_; }
sub worker_done    {
	my $self = shift;
	warn "restarting";
	$self->spawn( sub { 
			      require StompTestApp;
			      StompTestApp->run();
		      } );
}
sub worker_started { shift; warn join ' ', @_; }
sub sig_child      { shift; warn join ' ', @_; }
no Moose;

my $manager = Manager->new();
$manager->run();

