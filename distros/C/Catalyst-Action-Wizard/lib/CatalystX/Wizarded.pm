=head1 NAME

CatalystX::Wizarded

=head1 AUTHORS

Pavel Boldin (), <davinchi@cpan.ru>

=cut

package CatalystX::Wizarded;

use strict;
use warnings;

require Catalyst::Controller;
require Catalyst::ActionChain;

sub wizard {
    my $c = shift;
    $c->action->wizard( $c, caller => [ caller ], @_ );
}

sub have_wizard {
    my $c = shift;
    Catalyst::Wizard::_current_wizard( $c );
}

sub import {
    my $self = shift;
    my $action_class = shift || 'Catalyst::Action::Wizard';
    Catalyst::Controller->_action_class($action_class);

#    use Data::Dumper;
#    warn Dumper \@Catalyst::ActionChain::ISA;
    s/^Catalyst::Action$/$action_class/ foreach @Catalyst::ActionChain::ISA;
#    warn Dumper \@Catalyst::ActionChain::ISA;

    my %defaults = (
	expires	    => 86400,
	instance    => 'Catalyst::Wizard',
    );

    while (my ($k, $v) = each %defaults) {
	if (!exists(caller()->config->{wizard}{$k})) {
	    caller()->config->{wizard}{$k} = $v;
	}
    }

    {
	no strict 'refs';
	*{caller().'::wizard'}	    = \&wizard	   ;
	*{caller().'::have_wizard'} = \&have_wizard;
    }
}



1;
