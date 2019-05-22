package MockFurlMany;

#ABSTRACT: Furl Mockup class to return XML data from files based on queries
use Moo;
use Furl::Response;

sub get {
    my ($self, $url) = @_;
    $url =~ /startRecord=([^&]+)/;
    my $xml = do {local (@ARGV, $/) = "t/files/$1.xml"; <>};
    Furl::Response->new(1, 200, 'Ok', {}, $xml);
}

1;
