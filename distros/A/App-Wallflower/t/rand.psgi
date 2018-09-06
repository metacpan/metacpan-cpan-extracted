# an app generating random pages containing random links
my $max = 15;
my $app = sub {
    my ($env) = @_;
    $env->{REQUEST_URI} =~ m{/(\d+)};
    srand( $1 || 0 );
    my $html = join "\n",
      '<html><head></head><body>',
      map ( qq{<a href="/$_">$_</a>}, map int rand $max, 0 .. rand $max ),
      "</body><html>";
    [
        200,
        [ 'Content-Type' => 'text/html', 'Content-Length' => length($html) ],
        [$html]
    ];
};
