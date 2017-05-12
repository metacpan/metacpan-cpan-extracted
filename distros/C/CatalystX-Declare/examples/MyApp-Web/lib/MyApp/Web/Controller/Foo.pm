use CatalystX::Declare;

# a normal controller example
controller MyApp::Web::Controller::Foo {

    # this local base action chains to the root /base action
    action base under '/base' as 'foo';

    # all that's below base
    under base {

        # say hello
        final action hello {
            $ctx->stash(hello => 'rendering via root controller role');
        }

        # collecto two ints from the uri
        action nums (Int $x, Int $y) as '' under base {

            # stash the two values
            $ctx->stash(x => $x, y => $y);
        }

        # the nums action above has to two chain parts below it
        under nums {

            # one end-point where we add the numbers
            final action add { $ctx->res->body( $ctx->stash->{x} + $ctx->stash->{y} ) }

            # and one end-point where we multiply them
            final action multiply { $ctx->res->body( $ctx->stash->{x} * $ctx->stash->{y} ) }
        }
    }
}
