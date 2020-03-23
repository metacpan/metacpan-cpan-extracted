package MockHTTPClient;

#ABSTRACT: HTTP::Tiny mockup class to return XML data from file based on a query
use Moo;

sub get {
    my ($self, $url) = @_;
    $url =~ /query=([^&]+)/;
    my $xml = do {local (@ARGV, $/) = "t/$1"; <>};
    {success => 1, status => 200, reason => 'OK', content => $xml,};
}

1;
