package MyBase::MyApp;
use base 'MyBase';
use strict;
use CGI::Application::Plugin::ViewCode;

=head1 NAME MyBase::MyApp - Stuff

=cut

sub setup {
    my $self = shift;
    $self->run_modes(
        stuff => 'stuff',
    );

    $self->start_mode('stuff');
}

sub stuff {
    my $self = shift;
    return qq(Some Stuff);
}

1;
