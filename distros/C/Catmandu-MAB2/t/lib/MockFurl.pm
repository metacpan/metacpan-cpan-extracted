package MockFurl;
#ABSTRACT: Furl Mockup class to return XML data from file based on a query
use Moo;
use Furl::Response;

sub get {
    my ($self, $url) = @_;
    $url =~ /query=([^&]+)/;
	my $xml = do { local (@ARGV,$/) = "t/$1"; <> };
    Furl::Response->new(1,200,'Ok',{}, $xml);
}

1;
