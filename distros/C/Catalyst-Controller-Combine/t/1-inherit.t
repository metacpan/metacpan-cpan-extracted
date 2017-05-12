use Test::More;
use Test::Exception;
use Catalyst ();
use Catalyst::Controller::Combine ();
use FindBin;
use Path::Class::File;

# a simple package
{
    package MyApp::Controller::Js;
    use Moose;
    extends 'Catalyst::Controller::Combine';

    __PACKAGE__->config(
        # dir => 'static/js', # redundant, defaults to static/<<action_namespace>>
        # extension => 'js',  # redundant, defaults to <<action_namespace>>
        depend => {
            js2 => 'js1',
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
lives_ok { $controller = $c->setup_component('MyApp::Controller::Js') } 'setup component worked';

is(ref($controller), 'MyApp::Controller::Js', 'controller class looks good');
ok($controller->isa('Catalyst::Controller::Combine'), 'is a Catalyst::Controller::Combine');

# checking default attributes
is($controller->dir, 'static/js', 'default directory looks good');
is($controller->extension, 'js', 'default extension looks good');
is(ref($controller->depend), 'HASH', 'default dependency is HASH');
is_deeply($controller->depend, {js2 => 'js1'}, 'default dependency looks good');
is($controller->minifier, 'minify', 'default minify sub looks good');

# case 1: one file, no extension given
lives_ok {$controller->_collect_files($c, 'js1')} 'collect #1 works';
is_deeply($controller->{parts}, ['js1'], '1 part');
is_deeply($controller->{files}, ["" . Path::Class::File->new($FindBin::Bin, qw(root static js js1.js))], '1 file');
is_deeply($controller->{seen}, {js1 => 0}, '1 file seen once');

# case 2: one file, no extension given -- dependency should add one
lives_ok {$controller->_collect_files($c, 'js2')} 'collect #2 works';
is_deeply($controller->{parts}, ['js1','js2'], '2 parts');
is_deeply($controller->{files}, 
          ["" . Path::Class::File->new($FindBin::Bin, qw(root static js js1.js)),
           "" . Path::Class::File->new($FindBin::Bin, qw(root static js js2.js))], '2 files');
    # "$FindBin::Bin/root/static/js/js1.js","$FindBin::Bin/root/static/js/js2.js"], '2 files');
is_deeply($controller->{seen}, {js1 => 1, js2 => 0}, '2 files seen once');

# case 3: two files, no extension given
lives_ok {$controller->_collect_files($c, 'js1','js2')} 'collect #3 works';
is_deeply($controller->{parts}, ['js1','js2'], '2 parts');
is_deeply($controller->{files}, 
          ["" . Path::Class::File->new($FindBin::Bin, qw(root static js js1.js)),
           "" . Path::Class::File->new($FindBin::Bin, qw(root static js js2.js))], '2 files');
is_deeply($controller->{seen}, {js1 => 1, js2 => 0}, '2 files seen once');

done_testing;
