package MyAppActionChain::Plugin::Setup1;

use strict;

sub setup {

    my($self, @argv) = @_;
    $main::RESULT{setup1} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;
