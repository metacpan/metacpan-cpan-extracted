use Data::Delete;
use Test::More;

my $dd = Data::Delete->new;

{
    my $deep_data_structure = {
        id            => 4,
        last_modified => undef,
        sections      => [
            {
                content => 'h1. Ice Cream',
                class   => 'textile'
            },
            {
                content => '# Pie',
                class   => ''
            },
        ],
    };

    my $expected_result = {
        id       => "4",
        sections => [
            {
                content => 'h1. Ice Cream',
                class   => 'textile'
            },
            {
                content => "# Pie",
            }
        ]
    };

    is_deeply( $dd->delete($deep_data_structure),
        $expected_result, 'Trivial hash values deleted' );
}

{
    my $arrayref =
      [ 1, '0', { fu => 'bar', bon => undef }, { a => undef, b => q{} }, 'z' ];

    my $expected_result = [ 1, '0', { 'fu' => 'bar' }, {}, 'z' ];
    is_deeply( $dd->delete($arrayref), $expected_result, 'ArrayRef handled' );
    
    my $dd_dos = Data::Delete->new( will_delete_empty_string => 0 );
    my $expected_result_dos = [ 1, '0', { 'fu' => 'bar' }, { b => q{} }, 'z' ];
    is_deeply( $dd_dos->delete($arrayref), $expected_result_dos, 'empty string preserved' );
}

done_testing;
