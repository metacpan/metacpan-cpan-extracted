package CatalystX::OAuth2::Provider::TraitFor::Controller::OAuth::AuthorizationCode;

use MooseX::MethodAttributes::Role;
use OAuth::Lite::Token;
use namespace::autoclean;

requires qw/
    handle_grant_type
/;

around 'handle_grant_type' => sub {
    my ( $orig, $self, $ctx, $grant_type ) = @_;

    if (! $ctx->session->{token}) {
       my $t = OAuth::Lite::Token->new_random;
       $ctx->session->{token} = $t->token;
    }

    if ( $grant_type && ( $grant_type eq 'authorization_code' ) ) {
        my %data = (  access_token  =>  $ctx->session->{token},
                      expires_in    =>  3600,  #TODO: Make access_token expires
                      scope         =>  undef, #TODO: Support scope
                      refresh_token =>  $ctx->session->{token} );
        $ctx->res->body( JSON::XS->new->pretty(1)->encode( \%data ) );
        $ctx->detach();
    }

};

=pod
=cut

1;
