package t::lib::Mock;
use strict;
use warnings;

use base 'API::ParallelsWPB';

# ABSTRACT: mock for testing API::ParallelsWPB

# VERSION
# AUTHORITY

my %send_request_params = ();

{
    no warnings 'redefine';
    *API::ParallelsWPB::_send_request = sub {
        my ( $self, $data, $url, $post_data ) = @_;

        %send_request_params = (
            self      => $self,
            url       => $url,
            data      => $data,
            post_data => $post_data
        );

        my $res = HTTP::Response->new;
        # Mocking HTTP response for different methods
        if ( $url =~ m{/api/5.3/sites/$} ) {
            # Create site request
            $res->code( 200 );
            $res->content( '{"response":"6d3f6f9f-55b2-899f-5fb4-ae04b325e360"}' );
        }
        else {
            $res->code( 200 );
        }

        return API::ParallelsWPB::Response->new( $res );
    };
}

sub get_request_params { \%send_request_params }

1;
