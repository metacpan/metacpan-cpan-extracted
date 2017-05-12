package TestAppAltRoot::View::HTML::Root;
use Moose;

sub main {
    my ($self, $stash) = @_;
    $_->select("#name")->replace_content($stash->{name});
}

sub direct_render {
    my ($self, $stash) = @_;
    $_->select("#name")->replace_content($stash->{name});
}

1;
