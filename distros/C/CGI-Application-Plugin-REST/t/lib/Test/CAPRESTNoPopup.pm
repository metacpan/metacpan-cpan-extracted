package Test::CAPRESTNoPopup;
use strict;
use warnings;
use base 'CGI::Application';

BEGIN {
    delete $ENV{CAP_DEVPOPUP_EXEC};
}
use CGI::Application::Plugin::DevPopup;
use CGI::Application::Plugin::REST qw( rest_route );

sub setup {
    my ($self) = @_;

    $self->rest_route('/bar' => 'doop');

    return;
}

sub doop {
    my ($self) = @_;

    my $q = $self->query;

    no warnings;
    return $q->start_html(q{}) .
        CGI::Application::Plugin::REST::_rest_devpopup($self) .
        $q->end_html;
}

1;
