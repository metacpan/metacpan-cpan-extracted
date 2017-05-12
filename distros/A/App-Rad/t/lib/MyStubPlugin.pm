package MyStubPlugin;

sub my_method {
    my ($c, @args) = (@_);
    return $c->stash->{baz} . $args[1];
}

sub _my_own {}

42;
