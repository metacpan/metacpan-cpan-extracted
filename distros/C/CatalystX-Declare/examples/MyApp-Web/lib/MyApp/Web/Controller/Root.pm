use CatalystX::Declare;

namespace MyApp::Web;

# we consume a role that does what the RenderView action class
# would normally do
controller ::Controller::Root 
      with ::ControllerRole::RenderView {

    # $CLASS is provided by CLASS.pm
    $CLASS->config(namespace => '');


    # this is the common root action for all other actions
    action base under '/' as '';

    # we group all our root actions under the common base
    under base {

        # this action catches /
        final action root as '' {

            $ctx->response->body( $ctx->welcome_message );
        }

        # this action takes all other /* parts. the (@) signature
        # says we don't care about the arguments
        final action not_found (@) as '' {

            $ctx->response->body( 'Page Not Found' );
            $ctx->response->status( 404 );
        }
    }
}
