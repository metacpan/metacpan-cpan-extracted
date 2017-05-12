package Bricklayer::Templater::Handler::common::elsehashitem;
use Bricklayer::Templater::Handler;
use base qw(Bricklayer::Templater::Handler);

sub run {
    my $self = shift;
    my $arg  = shift;
	my $select = $self->attributes()->{key};
	my $contents = $self()->app()->run_sequencer($self->block(), $arg) unless $arg->{$select};
	return;
}

return 1;
