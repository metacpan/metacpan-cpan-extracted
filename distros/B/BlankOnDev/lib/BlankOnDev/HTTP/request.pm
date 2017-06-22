package BlankOnDev::HTTP::request;
use strict;
use warnings FATAL => 'all';

# Import :
use LWP::UserAgent ();
use HTTP::Request::Common;

# Version :
our $VERSION = '0.1005';;

# Subroutine for HTTP Request GET :
# ------------------------------------------------------------------------
sub get {
    my ($self, $url) = @_;
    my %data = ();

    my $ua = LWP::UserAgent->new;
    $ua->timeout(20);
    $ua->env_proxy;
    my $response = $ua->get($url);

    if ($response->is_success) {
        $data{'result'} = 1;
        $data{'data'} = $response->decode_content;
    }
    else {
        $data{'result'} = 0;
        $data{'data'} = '';
    }
}
1;