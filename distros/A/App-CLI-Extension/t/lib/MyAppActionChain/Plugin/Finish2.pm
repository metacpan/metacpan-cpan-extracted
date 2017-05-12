package MyAppActionChain::Plugin::Finish2;

use strict;

sub finish {

    my($self, @argv) = @_;
    $main::RESULT{finish2} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;
