package TestApp::View::HTML::Foo;
use Moose;
use namespace::autoclean;

has test_arg => (
    is => 'ro',
    required => 1,
);

sub bar {
    my ($self, $stash) = @_;
    $_->select('#name')->replace_content($stash->{name});
}

__PACKAGE__->meta->make_immutable;
