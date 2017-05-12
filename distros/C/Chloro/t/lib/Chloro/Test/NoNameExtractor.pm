package Chloro::Test::NoNameExtractor;

use Moose;
use Chloro;

use Chloro::Types qw( Str );

field foo => (
    isa       => Str,
    required  => 1,
    extractor => '_extract_foo',
);

sub _extract_foo {
    my $self   = shift;
    my $params = shift;
    my $prefix = shift;
    my $field  = shift;

    return $params->{foo};
}

__PACKAGE__->meta()->make_immutable;

1;
