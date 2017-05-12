#!perl 

use strict;
use Test::More;
use Data::Dumper;
use FindBin;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $validator = Data::Validate::WithYAML->new(
    $FindBin::Bin . '/test_datatypes.yml',
);

my @positives      = (
    {
        age   => 5,
        sum   => 5,
        index => 6,
    },
    {
        age   => 1,
        sum   => 5.5,
        index => -3,
    },
    {
        age   => 18,
        sum   => 0.0,
        index => 0,
    },
    {
        age   => 18,
        sum   => 9.9999999,
        index => 10e5,
    },
);

for my $case ( @positives ) {
    my %errors_positive = $validator->validate( 'default', %{$case} );
    is_deeply \%errors_positive, {}, 'correct values ' . flatten($case);
}

my @negative_check = (
    {
        age   => 'Age must be of type positive_int',
        sum   => 'Sum must be of type num',
        index => 'Index must be of type int',
    },
) x 3;
my @negative       = (
    {
        age   => 0,
        sum   => 's',
        index => 3.5,
    },
    {
        age   => 'r',
        sum   => bless( {}, 'main' ),
        index => 'r',
    },
    {
        age   => 1118,
        sum   => undef,
        index => '',
    },
);

for my $i ( 0 .. $#negative ) {
    my $case  = $negative[$i];
    my $check = $negative_check[$i];

    my %errors_negative = $validator->validate( 'default', %{$case} );
    is_deeply \%errors_negative, $check, 'negative values ' . flatten( $case );
}

done_testing();

sub flatten {
    my $data = shift;

    my $string = join ', ', map{ "$_ => $data->{$_}" }sort keys %{$data};
    return $string;
}
