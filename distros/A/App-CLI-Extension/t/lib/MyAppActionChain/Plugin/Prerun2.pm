package MyAppActionChain::Plugin::Prerun2;

use strict;

sub prerun {

    my($self, @argv) = @_;
    $main::RESULT{prerun2} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;

