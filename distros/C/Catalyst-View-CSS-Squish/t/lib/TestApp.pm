package TestApp;

use Catalyst qw/-Log=Info/;

__PACKAGE__->setup();

sub index : Private {
    my ($self,$c) = @_;
    $c->stash->{template}='1.css 2.css';
    $c->forward($c->view('Squish'));
}
sub test : Local {
    my ($self,$c) = @_;
    $c->stash->{template}=[qw/1.css 2.css/];
    $c->forward($c->view('Squish'));
}

1;
