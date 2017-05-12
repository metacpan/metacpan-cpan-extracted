package RestTest::ControllerBase::REST;

use strict;
use warnings;

use parent qw/Catalyst::Controller::DBIC::API::REST/;

sub create :Private {
my ($self, $c) = @_;
$self->next::method($c);
    if ($c->stash->{created_object}) {
        %{$c->stash->{response}->{new_object}} = $c->stash->{created_object}->get_columns;
    }
}

1;
