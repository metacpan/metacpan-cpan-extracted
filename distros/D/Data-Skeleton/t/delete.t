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

    my $result = $dd->delete($deep_data_structure);
    is_deeply( $result, $expected_result, 'Trivial hash values deleted' );
}

{
    my $arrayref =
      [ 1, '0', { fu => 'bar', bon => undef }, { a => undef, b => q{} }, 'z' ];

    my $expected_result = [ 1, '0', { 'fu' => 'bar' }, {}, 'z' ];
    my $result = $dd->delete($arrayref);
    is_deeply( $result, $expected_result, 'ArrayRef handled' );
    
    my $dd_dos = Data::Delete->new( will_delete_empty_string => 0 );
    my $expected_result_dos = [ 1, '0', { 'fu' => 'bar' }, { b => q{} }, 'z' ];
    $result = $dd_dos->delete($arrayref);
    is_deeply( $result, $expected_result_dos, 'empty string preserved' );
}

{
    my $data = {that_which_is_not => undef, empty_arrayref => [], empty_hashref => {}, empty_scalarref => \''};
    my $expect = {};
    my $dd_dor = Data::Delete->new( will_delete_empty_ref => 1 );
    my $got = $dd_dor->delete($data);
    is_deeply($got, $expect, 'delete empty ref');
}

done_testing;
