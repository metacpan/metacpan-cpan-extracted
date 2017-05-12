package Bricklayer::Templater::Handler::common::arrayitem;
use Bricklayer::Templater::Handler;
use base qw(Bricklayer::Templater::Handler);

sub run {
	my $self = shift;
	my $App =  $self->app();
	my $Data = $self->data();
	my $select = $self()->attributes()->{"index"};
	$select = $#$Data if ($Data->[$select] eq "last");
	return undef unless $Data->[$select];
	my $test = "|".ref($Data->[$select]);
	return $Data->[$select] if $test eq "|";
	$self->app()->run_sequencer($self->block(), $Data->{$select}) if $Data->{$select};
	return;
}

return 1;
