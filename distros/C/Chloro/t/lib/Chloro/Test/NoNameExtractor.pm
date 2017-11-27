package Chloro::Test::NoNameExtractor;

use Moose;
use namespace::autoclean;

use Chloro;

use Chloro::Types qw( Str );

field foo => (
    isa       => Str,
    required  => 1,
    extractor => '_extract_foo',
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _extract_foo {
    my $self   = shift;
    my $params = shift;

    return $params->{foo};
}
## use critic

__PACKAGE__->meta()->make_immutable;

1;
