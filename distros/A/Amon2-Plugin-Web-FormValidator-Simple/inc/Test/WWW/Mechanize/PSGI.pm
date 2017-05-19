#line 1
package Test::WWW::Mechanize::PSGI;
use strict;
use warnings;
use Carp;
use HTTP::Message::PSGI;
use Test::WWW::Mechanize;
use Try::Tiny;
use base 'Test::WWW::Mechanize';
our $VERSION = '0.35';

my $Test = Test::Builder->new();

sub new {
    my $class = shift;
    my %args  = @_;

    # Dont let LWP complain about options for our attributes
    my $app = $args{app};
    delete $args{app};
    confess('Missing argument app') unless $app;
    confess('Argument app should be a code reference')
        unless ref($app) && ref($app) eq 'CODE';

    my $self = $class->SUPER::new(%args);
    $self->{app} = $app;
    return $self;
}

sub simple_request {
    my ( $self, $request ) = @_;

    my $uri = $request->uri;
    $uri->scheme('http')    unless defined $uri->scheme;
    $uri->host('localhost') unless defined $uri->host;

    my $env = $self->prepare_request($request)->to_psgi;
    my $response;
    try {
        $response = HTTP::Response->from_psgi( $self->{app}->($env) );
    }
    catch {
        $Test->diag("PSGI error: $_");
        $response = HTTP::Response->new(500);
        $response->content($_);
        $response->content_type('');
    };
    $response->request($request);
    $self->run_handlers( "response_done", $response );
    return $response;
}

1;

__END__

