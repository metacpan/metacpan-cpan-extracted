package Bricklayer::Templater::Handler::common::ifhashitem;
use Bricklayer::Templater::Handler;
use base qw(Bricklayer::Templater::Handler);

sub run {
    my $self = shift;
    my $arg = shift;
	my $select = $self()->attributes()->{key};
	my $contents;
	$self->app()->run_sequencer($self->block(), $arg) if $arg->{$select};
	if ($self->attributes()->{"else"}) {
		$contents = $self->attributes()->{"else"} unless ($arg->{$select});
	}
	return $contents;
}

return 1;
