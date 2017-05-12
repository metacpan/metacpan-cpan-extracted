package Bricklayer::Templater::Handler::common::row;
use Bricklayer::Templater::Handler;
use Carp;
use base qw(Bricklayer::Templater::Handler);

sub run {
	my $self = shift;
    my $Token = $self->{Token};
	my $App =  $self->app();
	my $block = $Token->{block};
	my $loop = shift;
	carp("in the row handler with $loop");
    # start our loop sequence
	if (ref($loop) eq "ARRAY") {
        carp('got passed an array');
		foreach my $item (@{$loop}) {
            carp("Looping through the array");
			$App->run_sequencer($block, $item);
		}	
	}
	return;
}

return 1;
