package MyAppActionChain::Plugin::Prerun1;

use strict;

sub prerun {

    my($self, @argv) = @_;
    $main::RESULT{prerun1} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;
