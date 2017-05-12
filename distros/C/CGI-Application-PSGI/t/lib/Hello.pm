package Hello;
use base qw(CGI::Application);

sub setup {
    my $self = shift;
    $self->start_mode('hello');
    $self->mode_param('rm');
    $self->run_modes('hello' => 'hello', 'hello_redir' => 'hello_redir');
}

sub hello_redir {
    my $self = shift;

    $self->header_type('redirect');
    $self->header_props(-url => "/foo");
}

sub hello {
    my $self = shift;

    $self->header_props(-type => 'text/plain');
    my $query = $self->query;
    return "Hello " . $query->param('name');
}

1;

