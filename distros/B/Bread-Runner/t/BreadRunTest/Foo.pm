package BreadRunTest::Foo;
use Moose;

sub foo_it {
    return 'FOO';
}

__PACKAGE__->meta->make_immutable;
