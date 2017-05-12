package # hide from PAUSE
    TestApp::Controller::Form;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use base qw/TestApp::Controller::Base/;
#use base qw/Catalyst::Controller::Validation::DFV/;

sub first : Local {
    my ($self, $c) = @_;
    #$c->stash->{template} = "form/first.tt";
}

1;
__END__
