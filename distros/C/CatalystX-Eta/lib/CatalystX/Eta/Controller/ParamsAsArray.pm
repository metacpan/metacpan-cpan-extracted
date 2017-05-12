package CatalystX::Eta::Controller::ParamsAsArray;

use Moose::Role;

=pod

Transform keys of a hash to array.


$self->params_as_array( 'foo', {
    'foo:1' => 'a',
    'bar:1' => 'b',
    'zoo:1' => 1,
    'zoo:2' => 2,
})

Returns:

[
    { foo => 'a', zoo => 1},
    { foo => 'b', zoo => 2}
]

=cut

sub params_as_array {
    my ( $self, $splt, $c_req_params ) = @_;

    my $out          = {};
    my $idx_visibles = {};

    foreach my $k ( keys %$c_req_params ) {
        next unless $k =~ /^$splt:([^\:]+):([0-9]+)$/;

        my ( $name, $idx ) = ( $1, $2 );

        $out->{$idx}{$name} = $c_req_params->{$k};
        $idx_visibles->{$idx}++;
    }

    # check if all items are with the same number of keys
    my $last;
    foreach my $idx ( keys %$idx_visibles ) {
        my $v = $idx_visibles->{$idx};
        $last = $v unless defined $last;
        die 'invalid "real_(name):(index)" parameters' if $last != $v;
    }

    my $array = [];
    foreach my $idx ( keys %$idx_visibles ) {

        my $item = {};
        foreach my $name ( keys %{ $out->{$idx} } ) {
            $item->{$name} = $out->{$idx}{$name};
        }
        push @$array, $item;
    }

    return $array;
}
