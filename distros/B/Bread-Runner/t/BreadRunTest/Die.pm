package BreadRunTest::Die;
use Moose;

sub run {
    die 'hard';
}

__PACKAGE__->meta->make_immutable;
