package Chloro::Test::CompoundDate;

use Moose;
use Chloro;

use Chloro::Types qw( Str );

field date => (
    isa       => Str,
    required  => 1,
    extractor => '_extract_date',
);

sub _extract_date {
    my $self   = shift;
    my $params = shift;
    my $prefix = shift;
    my $field  = shift;

    my @keys = qw( year month day );

    if ( defined $prefix ) {
        $_ = join q{.}, $prefix, $_ for @keys;
    }

    return ( join '-', @{$params}{@keys} ), ( 'year', 'month', 'day' );
}

__PACKAGE__->meta()->make_immutable;

1;
