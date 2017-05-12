BEGIN {
    no warnings 'redefine';
    require Catalyst::Test;

    *Catalyst::Test::local_request = sub {
        my ( $class, $request ) = @_;
        use Data::Dumper;

        require HTTP::Request::AsCGI;
        require Catalyst::Utils;
        $request = ref($request) ? $request : Catalyst::Utils::request($request);
        my $cgi = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

        $class->handle_request;

        return $cgi->restore->response;
    };
}

1;
