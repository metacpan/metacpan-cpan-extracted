package BreadRunTest::Psgi;
use Moose;

has foo => (
    is=>'ro',
    required=>1,
);

sub run {
    my $self = shift;
    return $self->foo->foo_it;
}

__PACKAGE__->meta->make_immutable;
