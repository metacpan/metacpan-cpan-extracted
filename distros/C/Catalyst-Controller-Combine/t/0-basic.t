use Test::More;
use Test::Exception;
use Catalyst ();
use FindBin;
use Path::Class::File;

# setup our Catalyst :-)
my $c = Catalyst->new();
$c->setup_log();
$c->setup_home("$FindBin::Bin");

#
# test start...
#
# can we use it?
use_ok 'Catalyst::Controller::Combine';

# check for public methods
can_ok('Catalyst::Controller::Combine' => qw(do_combine default uri_for));

# check for private methods
can_ok('Catalyst::Controller::Combine' => qw(_collect_files _check_dependencies));

# instantiate
my $controller;
lives_ok { $controller = $c->setup_component('Catalyst::Controller::Combine') } 'setup component worked';

is(ref($controller), 'Catalyst::Controller::Combine', 'controller class looks good');

# checking default attributes
is($controller->dir, 'static/combine', 'default directory looks good');
is($controller->extension, 'combine', 'default extension looks good');
is(ref($controller->depend), 'HASH', 'default dependency is HASH');
ok(scalar(keys(%{$controller->depend})) == 0, 'default dependency is empty');
is($controller->minifier, 'minify', 'default minify sub looks good');

#
# set some defaults and see if low level functions are working
#
$controller->dir('static/js');
$controller->extension('js');

# case 1: no file at all
lives_ok {$controller->_collect_files('Catalyst')} 'collect #1 works';
is_deeply($controller->{parts}, [], 'no parts');
is_deeply($controller->{files}, [], 'no files');
is_deeply($controller->{seen}, {}, 'nothing seen');

# case 2: one file, no extension given
lives_ok {$controller->_collect_files('Catalyst', 'js1')} 'collect #2 works';
is_deeply($controller->{parts}, ['js1'], '1 part');
is_deeply($controller->{files}, ["" . Path::Class::File->new($FindBin::Bin, qw(root static js js1.js))], '1 file');
is_deeply($controller->{seen}, {js1 => 0}, '1 file seen once');

# case 3: one file, extension given
lives_ok {$controller->_collect_files('Catalyst', 'js1.js')} 'collect #3 works';
is_deeply($controller->{parts}, ['js1'], '1 part');
is_deeply($controller->{files}, ["" . Path::Class::File->new($FindBin::Bin, qw(root static js js1.js))], '1 file');
is_deeply($controller->{seen}, {js1 => 0}, '1 file seen once');

# case 4: one file, strange extension given
lives_ok {$controller->_collect_files('Catalyst', 'js1.xxx')} 'collect #4 works';
is_deeply($controller->{parts}, [], 'no parts');
is_deeply($controller->{files}, [], 'no files');
is_deeply($controller->{seen}, {}, 'nothing seen');

# case 5: non existing file, no extension given
lives_ok {$controller->_collect_files('Catalyst', 'jsxx1')} 'collect #5 works';
is_deeply($controller->{parts}, [], 'no parts');
is_deeply($controller->{files}, [], 'no files');
is_deeply($controller->{seen}, {}, 'no files seen');

# case 6: combination of existing and non existing files
lives_ok {$controller->_collect_files('Catalyst', 'js1.js', 'jsx.js', 'jsy', 'js2')} 'collect #6 works';
is_deeply($controller->{parts}, ['js1', 'js2'], '2 parts');
is_deeply($controller->{files}, 
          ["" . Path::Class::File->new($FindBin::Bin, qw(root static js js1.js)),
           "" . Path::Class::File->new($FindBin::Bin, qw(root static js js2.js))], '2 files');
is_deeply($controller->{seen}, {js1 => 0, js2 => 0}, '2 file seen once');

#
# response generation
#
lives_ok {$controller->do_combine($c, 'js1')} 'do_combine #1 works';
like($c->response->body, qr{/\* \s javascript \s 1 \s \*\/\s*}xms, 'response looks good');

done_testing;
