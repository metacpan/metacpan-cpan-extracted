package MyTestHelper;
use base qw/Catalyst::Helper/;

sub example_render {
    my ($self, $fn, $vars) = @_;
    $self->render_file('example1', $fn, $vars);
}

1;

__DATA__
__example1__
foobar[% test_var %]
__example2__
bazquux
