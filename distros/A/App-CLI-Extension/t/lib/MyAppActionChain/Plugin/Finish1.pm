package MyAppActionChain::Plugin::Finish1;

use strict;

sub finish {

    my($self, @argv) = @_;
    $main::RESULT{finish1} = __PACKAGE__; 
    $self->maybe::next::method(@argv);
}

1;
