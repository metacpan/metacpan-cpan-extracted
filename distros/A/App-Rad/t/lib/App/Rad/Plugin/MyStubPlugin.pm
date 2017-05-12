package App::Rad::Plugin::MyStubPlugin;

sub my_other_method {
    my ($c, @args) = (@_);
    return $c->stash->{baz} . $args[1];
}

sub _my_very_own {}

42;
