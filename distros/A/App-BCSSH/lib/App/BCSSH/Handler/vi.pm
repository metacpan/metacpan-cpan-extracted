package App::BCSSH::Handler::vi;
use Moo;

with 'App::BCSSH::Handler';

has gvim => (is => 'ro', default => sub { 'gvim' });

sub handle {
    my ($self, $send, $args) = @_;
    my $files = $args->{files};
    my $wait = $args->{wait};
    for my $file (@$files) {
        $file = 'scp://'.$self->host.'/'.$file;
    }
    system $self->gvim, ($wait ? '-f' : ()), '--', @$files;
    $send->();
}

1;
