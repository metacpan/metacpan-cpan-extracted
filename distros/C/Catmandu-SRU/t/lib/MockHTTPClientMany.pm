package MockHTTPClientMany;

#ABSTRACT: HTTP::Tiny mockup class to return XML data from files based on queries
use Moo;

sub get {
    my ($self, $url) = @_;
    $url =~ /startRecord=([^&]+)/;
    my $xml = do {local (@ARGV, $/) = "t/files/$1.xml"; <>};
    {success => 1, status => 200, reason => 'OK', content => $xml,};
}

1;
