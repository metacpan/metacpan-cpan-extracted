use HTTP::Date qw( str2time );

my %response = (
    '/' => [ 'text/html', << 'HTML' ],
<html><head></head><body>
<a href="/dir">dir (301)</a>
</body>
HTML
    '/dir' => '/dir/',                         # redirect
    '/dir/' => [ 'text/html' => << 'HTML' ],
<html><head></head><body>
<a href="/">Home</a>
<a href="/text.html">Text</a>
</body>
HTML
'/text.html' => [ 'text/html' => << 'HTML' ],
<html><head></head><body>
A link to <a href="http://www.cpan.org">CPAN</a>.
</body>
HTML
);
my %generated;

my $app = sub {
    my ($env) = @_;
    my $res = $response{ $env->{REQUEST_URI} };

    return [ 304, [ 'Content-Type' => $res->[0] ], [] ]
      if ref $res
      && $env->{HTTP_IF_MODIFIED_SINCE}
      && ( $generated{ $env->{REQUEST_URI} } || 0 ) <
      str2time( $env->{HTTP_IF_MODIFIED_SINCE} );
    $generated{ $env->{REQUEST_URI} } = time;

    return !defined $res
      ? [ 404, [ 'Content-Type' => 'text/plain', 'Content-Length' => 0 ], [''] ]
      : ref $res ? [
        200,
        [
            'Content-Type'   => $res->[0],
            'Content-Length' => length( $res->[1] )
        ],
        [ $res->[1] ]
      ]
      : [ 301, [ Location => $res ], [''] ];
};
