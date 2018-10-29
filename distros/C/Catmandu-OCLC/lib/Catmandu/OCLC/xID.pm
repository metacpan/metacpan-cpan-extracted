package Catmandu::OCLC::xID;

use LWP::Simple;
use URI::Escape;
use JSON::MaybeXS;

sub query {
    my $query   = shift;
    my $type    = shift;
    my $method  = shift;

    die "usage: query(query,type,method)" unless defined $query &&
                                                       defined $type &&
                                                       defined $method;
    my $endpoint;

    if ($type eq 'xisbn') {
    	$endpoint = 'http://xisbn.worldcat.org/webservices/xid/isbn';
    }
    elsif ($type eq 'xissn') {
    	$endpoint = 'http://xisbn.worldcat.org/webservices/xid/issn';
    }
    elsif ($type eq 'xstandardNumber') {
   		$endpoint = 'http://xisbn.worldcat.org/webservices/xid/oclcnum';
    }
    else {
    	$endpoint = 'http://xisbn.worldcat.org/webservices/xid/isbn';
    }

    my $request  = sprintf "%s/%s?method=%s&format=json&fl=*"
                            , $endpoint
                            , uri_escape($query)
                            , $method;

    my $response = get($request);
    my $json     = JSON::MaybeXS->new->utf8(0);

    my $perl;
    eval {
        $perl = $json->decode($response);
    };
    if ($@) {
        $perl = { error => $@ };
    }

    $perl;
}

1;

__END__

=head1 NAME

Catmandu::OCLC::xID - OCLC xID services offline since 2018-08-23

=cut
