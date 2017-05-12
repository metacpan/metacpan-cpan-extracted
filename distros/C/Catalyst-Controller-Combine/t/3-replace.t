use Test::More;
use Test::Exception;
use Catalyst ();
use Catalyst::Controller::Combine ();
use FindBin;
use Path::Class::File;

# a simple package
{
    package MyApp::Controller::Css;
    use Moose;
    extends 'Catalyst::Controller::Combine';

    __PACKAGE__->config(
        # dir => 'static/css', # redundant, defaults to static/<<action_namespace>>
        # extension => 'css',  # redundant, defaults to <<action_namespace>>
        depend => {
            css1 => 'base',
            css2 => 'css1',
        },
        
        replace => {
            '*'    => [ 'xx' => 'REPL:\\$1' ],
            'css*' => [ a => 'b', qr{u+} => 'v' ],
            'css2' => [ url => 'URI' ],
        },
        # will be guessed from extension
        # mimetype => 'application/javascript',
    );
}

# setup our Catalyst :-)
my $c = Catalyst->new();
$c->setup_log();
$c->setup_home("$FindBin::Bin");

my $controller;
lives_ok { $controller = $c->setup_component('MyApp::Controller::Css') } 'setup component worked';

done_testing;

### TODO: append a reasonable test...
