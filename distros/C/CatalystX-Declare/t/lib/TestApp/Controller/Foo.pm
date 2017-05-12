use CatalystX::Declare;

namespace TestApp;

controller ::Controller::Foo with ::TestRole {

    use constant MyActionNo => 'TestApp::Try::Aliasing::MyActionNo';

    class ::Messenger {

        has message => (is => 'rw');

        method format { uc $self->message }
    }

    role MyActionYes {
        around match (@args) { $ENV{TESTAPP_ACTIONROLE} ? $self->$orig(@args) : undef }
    }

    role TestApp::Try::Aliasing::MyActionNo {
        around match (@args) { $ENV{TESTAPP_ACTIONROLE} ? undef : $self->$orig(@args) }
    }

    class TestApp::Action::Page extends Catalyst::Action {

        around execute ($controller, $ctx, @args) {
            my $page = $ctx->request->params->{page} || 1;
            $ctx->stash(page => $page);
            return $self->$orig($controller, $ctx, @args);
        }
    }

    #
    #   look, a Moose!
    #

    has title => (
        is      => 'ro',
        isa     => 'Str',
        default => 'TestApp',
    );


    #
    #   normal methods are very useful too
    #

    method welcome_message { sprintf 'Welcome to %s!', $self->title }

    method greet (Str $name) { "Hello, $name!" }


    #
    #   the simple stuff
    #

    action base under '/base' as 'foo';

    action root under base as '' is final {
        $ctx->response->body( $self->welcome_message );
    }

    
    #
    #   with arguments
    #

    action with_args under base;

    action hello (Str $name) under with_args is final {
        $ctx->response->body($self->greet(ucfirst $name));
    }

    action at_end (Int $x, Int $y) under with_args is final { 
        $ctx->response->body( $x * $y );
    }

    action in_the_middle (Int $x, Int $y) under with_args {
        $ctx->stash(result => $x * $y);
    }
    action end_of_the_middle under in_the_middle is final {
        $ctx->response->body($ctx->stash->{result} * 2);
    }

    action all_the_way (Int $x) under with_args as '' {
        $ctx->stash(x => $x);
    }
    action through_the_sky (Int $y) under all_the_way as '' {
        $ctx->stash(y => $y);
    }
    action and_beyond (@rest) under through_the_sky as fhtagn is final {
        $ctx->response->body(join ', ', 
            $ctx->stash->{x},
            $ctx->stash->{y},
            @rest,
        );
    }


    #
    #   under is also a valid keyword
    #

    under base action under_base as under;

    under under_base as '' action even_more_under (Int $i) is final {
        $ctx->response->body("under $i");
    }


    #
    #   too many words? go comma go!
    #

    action comma_base, as '', under base;

    under comma_base, is final, action comma ($str), as ',comma' {
        $ctx->response->body($str);
    }


    #
    #   subnamespacing
    #

    action lower under base;

    under lower {

        action down;

        under down {

            action the;

            under the {

                action stream is final {
                    $ctx->response->body($ctx->action->reverse);
                }

                action param (Int $x) { 
                    $ctx->stash(param_x => $x);
                }

                under param {

                    final action road (Int $y) {
                        $ctx->response->body($ctx->stash->{param_x} + $y);
                    }
                }
            }
        }
    }


    #
    #   action roles
    #

    action with_role_yes 
        is final 
        as with_role 
     under base 
      with MyActionYes 
           { $ctx->res->body('YES') };

    action with_role_no 
        is final 
        as with_role 
     under base 
      with MyActionNo 
           { $ctx->res->body('NO') };


    #
    #   action classes
    #

    action book (Str $title) under base {
        $ctx->stash(title => $title);
    }

    action view (Str $format) under book isa Page is final {
        $ctx->response->body(
            sprintf 'Page %d of "%s" as %s',
                $ctx->stash->{page},
                $ctx->stash->{title},
                uc($format),
        );
    }


    #
    #   using final as syntax element
    #

    action final_base as 'finals' under base;

    final action in_front under final_base { $ctx->response->body($ctx->action->reverse) }

    under final_base, final action final_middle { $ctx->response->body($ctx->action->reverse) }

    action final_at_end, final under final_base { $ctx->response->body($ctx->action->reverse) }


    #
    #   privates
    #

    action not_really_here is private { $ctx->stash(foo => 23) }

    action expose_not_really_here under base is final { 
        $ctx->forward('not_really_here');
        $ctx->response->body($ctx->stash->{foo});
    }


    #
    #   chain target specified via action
    #

    action pointed <- base ($what) is final { $ctx->response->body("Your $what is pointed!") }


    #
    #   targets for action modifiers
    #

    action modifier_target under base is final { $ctx->response->body($ctx->action->reverse) }

    action surrounded_target under base is final { 
        $ctx->response->body(join ' ', $ctx->action->reverse, $ctx->response->body || ());
    }


    #
    #   inline classes
    #

    final action inline_class under base {
        $ctx->response->body( TestApp::Controller::Foo::Messenger->new(message => 'Hello')->format );
    }


    #
    #   validation test
    #

    final action wants_integer (Int $x) under base {
        $ctx->response->body($x);
    }

    final action wants_integer_fail (Any $x) as 'wants_integer' under base {
        $ctx->response->body('no integer');
    }

}

