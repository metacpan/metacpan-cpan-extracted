package MyAppActionChain::Plugin::Postrun1;

use strict;

sub postrun {

    my($self, @argv) = @_;
    $main::RESULT{postrun1} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;
