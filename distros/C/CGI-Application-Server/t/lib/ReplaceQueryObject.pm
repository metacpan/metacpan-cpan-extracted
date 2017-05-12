package ReplaceQueryObject;
use base 'CGI::Application';
use warnings;
use strict;

sub setup {
    my ($self) = @_;
    $self->run_modes([qw/ start /]);
}

sub start {
    my ($self) = @_;
    my $q = $self->query;
    return join "\n",
        $q->start_html($q->param('text')) .
        $q->end_html
    ;
}

1;

