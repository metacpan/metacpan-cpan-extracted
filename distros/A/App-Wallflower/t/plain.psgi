my $app = sub {
    my ($env) = @_;
    return [
        200,
        [
            'Content-Type'   => 'text/plain',
            'Content-Length' => length( $env->{REQUEST_URI} ),
        ],
        [ $env->{REQUEST_URI} ]
    ];
};
