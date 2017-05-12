package MyAppActionChain::Plugin::Postrun2;

use strict;

sub postrun {

    my($self, @argv) = @_;
    $main::RESULT{postrun2} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;
