#line 1
package Test::WWW::Mechanize::Catalyst;
use strict;
use warnings;
use Encode qw();
use HTML::Entities;
use Test::WWW::Mechanize;
use base qw(Test::WWW::Mechanize);
our $VERSION = "0.39";
my $Test = Test::Builder->new();

# the reason for the auxiliary package is that both WWW::Mechanize and
# Catalyst::Test have a subroutine named 'request'

sub _make_request {
    my ( $self, $request ) = @_;
    $self->cookie_jar->add_cookie_header($request) if $self->cookie_jar;

    unless ( $request->uri->as_string =~ m{^/}
        || $request->uri->host eq 'localhost' )
    {
        return $self->SUPER::_make_request($request);
    }

    $request->authorization_basic(
        LWP::UserAgent->get_basic_credentials(
            undef, "Basic", $request->uri
        )
        )
        if LWP::UserAgent->get_basic_credentials( undef, "Basic",
        $request->uri );

    my $response = Test::WWW::Mechanize::Catalyst::Aux::request($request);
    $response->header( 'Content-Base', $request->uri );
    $response->request($request);
    $self->cookie_jar->extract_cookies($response) if $self->cookie_jar;

    # fail tests under the Catalyst debug screen
    if (   !$self->{catalyst_debug}
        && $response->code == 500
        && $response->content =~ /on Catalyst \d+\.\d+/ )
    {
        my ($error)
            = ( $response->content =~ /<code class="error">(.*?)<\/code>/s );
        $error ||= "unknown error";
        decode_entities($error);
        $Test->diag("Catalyst error screen: $error");
        $response->content('');
        $response->content_type('');
    }

    # check if that was a redirect
    if (   $response->header('Location')
        && $self->redirect_ok( $request, $response ) )
    {

        # remember the old response
        my $old_response = $response;

        # *where* do they want us to redirect to?
        my $location = $old_response->header('Location');

        # no-one *should* be returning non-absolute URLs, but if they
        # are then we'd better cope with it.  Let's create a new URI, using
        # our request as the base.
        my $uri = URI->new_abs( $location, $request->uri )->as_string;

        # make a new response, and save the old response in it
        $response = $self->_make_request( HTTP::Request->new( GET => $uri ) );
        my $end_of_chain = $response;
        while ( $end_of_chain->previous )    # keep going till the end
        {
            $end_of_chain = $end_of_chain->previous;
        }                                          #   of the chain...
        $end_of_chain->previous($old_response);    # ...and add us to it
    } else {
        $response->{_raw_content} = $response->content;
        if (   $response->header('Content-Type')
            && $response->header('Content-Type') =~ m/charset=(\S+)/xms )
        {
            $response->content( Encode::decode( $1, $response->content ) );
        }
    }

    return $response;
}

sub import {
    Test::WWW::Mechanize::Catalyst::Aux::import(@_);
}

package Test::WWW::Mechanize::Catalyst::Aux;

sub import {
    my ( $class, $name ) = @_;
    eval "use Catalyst::Test '$name'";
    warn $@ if $@;
}

1;

__END__

