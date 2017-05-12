package Catmandu::CA::API::Login;

our $VERSION = '0.06';

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Data::Dumper qw(Dumper);

use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;

has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);
has url => (is => 'ro', required => 1);

has port => (is => 'lazy');
has ua   => (is => 'lazy');

sub _build_port {
    my $self = shift;
    # If the port is included
    if ($self->url =~ /^https?:\/\/[^\/:]:([0-9]+)\//) {
        return $1;
    }
    # If it is https
    if ($self->url =~ /^https/) {
        return '443';
    } else {
        # Anything else
        return '80';
    }
}

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => sprintf('catmandu-ca/%s', $VERSION)
    );
    return $ua;
}

sub token {
    my ($self) = @_;
    my $url = sprintf('%s/service.php/auth/login', $self->url);
    my $request = GET $url;
    $request->authorization_basic($self->username, $self->password);
    my $response = $self->ua->request($request);
    if ($response->is_success) {
        my $content = decode_json($response->decoded_content);
        return $content->{'authToken'};
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->status_line,
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
        });
        return undef;
    }
}

1;
__END__