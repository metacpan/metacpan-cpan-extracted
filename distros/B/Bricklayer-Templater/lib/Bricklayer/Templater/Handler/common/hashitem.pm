package Bricklayer::Templater::Handler::common::hashitem;
use Bricklayer::Templater::Handler;
use base qw(Bricklayer::Templater::Handler);

sub run {
    my $self = shift;
    my $arg  = shift;
	my $select = $self->attributes()->{key};
	return undef unless ref($arg) eq "HASH";
	my $test = "|".ref($arg->{$select});
	return $arg->{$select} if $test eq "|";
	$self->app()->run_sequencer($self->block(), $arg->{$select}) if $arg->{$select};
	return;
}

return 1;
