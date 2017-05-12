package MyAppActionChain::Plugin::Setup2;

use strict;

sub setup {

    my($self, @argv) = @_;
    $main::RESULT{setup2} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;
