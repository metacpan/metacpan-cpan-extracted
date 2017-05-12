#--------------------------------------------------------------------------
# 
# File: object.pm
# Version: 0.1
# Author: Jeremy Wall
# Definition: allows us to dereference objects in the template
#
# Note: This tags functionality has been shamelessly ripped off / inspired-
# from Template Toolkit. Many thanks Andy Wardly for the ideas.
#--------------------------------------------------------------------------
package Bricklayer::Templater::Handler::common::object;
use Carp;
use base qw(Bricklayer::Templater::Handler);


sub run {
	my ($self, $object) = @_;
	my $retrieve = $self->attributes()->{call};
	my $debug = $self->attributes()->{debug};
    carp("---Object is: ".ref($object)) if $debug;
    carp("---requesting: $retrieve") if $debug;
    my $passthrough = $self->attributes()->{nest};
	my $negate = $self->attributes()->{"not"};
	if (ref($object) ne "") {
		my $return;
		$retrieve =~ s/\./->/g;
		my $call = '$return = $object->'.$retrieve;
        carp("---running: [$call]") if $debug;
		eval $call;
        croak($@) if $@;
        carp("---the return was: $return") if defined $return and $debug;
		my $arg;
		if ($self->block) {
            carp('******'.$self->block()) if $debug;
			$arg = $return if $passthrough;
			$arg = $object unless $passthrough;
			if ($return || $negate) {
				return if $negate && $return;
			} else {
				return;
			}
			if ($self->attributes->{embed}) {
                carp("---the arg is: ".ref($arg)) if $debug;
				return &$arg();
			} else {
                carp("---before parse_block the arg is: ".ref($arg)) if $debug;
                $self->parse_block($arg);
                carp("---after parse_block the arg is: ".ref($arg)) if $debug;
			}
			return;
		}
		if ($self->attributes->{embed}) {
			return &$return();
		} else {
			return $return if !$negate;
		}
		return;
	} 
	return;
}

return 1;
