use Test::More;
use Test::LongString max => 500;
use strict;
use warnings;
use lib 't/lib';
my $COUNT;
plan(tests => $COUNT);

BEGIN { $COUNT += 5 }

# make sure we can get to our modules
require_ok('CGI::Application::Dispatch');
require_ok('Module::Name');
require_ok('MyApp::Module::Name');
require_ok('MyApp::Dispatch');
require_ok('MyApp::DispatchTable');
local $ENV{CGI_APP_RETURN_ONLY} = '1';
my $output = '';

# to capture and junk STDERR
my $junk;
{
    no strict;
    open SAVE_ERR, ">&STDERR";
    close STDERR;
    open STDERR, ">", \$junk
      or warn "Could not redirect STDERR?\n";

}

BEGIN { $COUNT += 1 }

# make sure that dispatch_path() is returning PATH_INFO
{
    local $ENV{PATH_INFO} = '/test/dispatch_path/';
    is(CGI::Application::Dispatch->dispatch_path, '/test/dispatch_path/',
       '->dispatch_path() is returning PATH_INFO');
}

BEGIN { $COUNT += 2 }

# module name
{

    # with starting '/'
    local $ENV{PATH_INFO} = '/module_name/rm1';
    my $output = CGI::Application::Dispatch->dispatch();
    contains_string($output, 'Module::Name->rm1', 'dispatch(): module_name');

    # without starting '/'
    local $ENV{PATH_INFO} = 'module_name/rm1';
    $output = '';
    $output = CGI::Application::Dispatch->dispatch();
    contains_string($output, 'Module::Name->rm1', 'dispatch(): module_name');
}

BEGIN { $COUNT += 1 }

# prefix
{
    local $ENV{PATH_INFO} = '/module_name/rm2';
    $output = CGI::Application::Dispatch->dispatch(prefix => 'MyApp',);
    contains_string($output, 'MyApp::Module::Name->rm2', 'dispatch(): prefix');
}

BEGIN { $COUNT += 1 }

# grabs the RM from the PATH_INFO
{

    # with run mode
    local $ENV{PATH_INFO} = '/module_name/rm2';
    $output = CGI::Application::Dispatch->dispatch(prefix => 'MyApp',);
    contains_string($output, 'MyApp::Module::Name->rm2', 'RM correct');
}

BEGIN { $COUNT += 1 }

# extra things passed to dispatch() get passed into new()
{
    local $ENV{PATH_INFO} = '/module_name/rm3';
    $output = CGI::Application::Dispatch->dispatch(
        prefix => 'MyApp',
        PARAMS => {my_param => 'testing',},
    );
    contains_string($output, 'MyApp::Module::Name->rm3 my_param=testing', 'PARAMS passed through');
}

BEGIN { $COUNT += 2 }

# use default
{

    # using short cuts names
    local $ENV{PATH_INFO} = '';
    $output = CGI::Application::Dispatch->dispatch(
        prefix  => 'MyApp',
        default => '/module_name/rm2',
    );
    contains_string($output, 'MyApp::Module::Name->rm2', 'default');

    # with trailing '/'
    local $ENV{PATH_INFO} = '/';
    $output = CGI::Application::Dispatch->dispatch(
        prefix  => 'MyApp',
        default => '/module_name/rm2',
    );
    contains_string($output, 'MyApp::Module::Name->rm2', 'default');
}

BEGIN { $COUNT += 1 }

# override translate_module_name()
{
    local $ENV{PATH_INFO} = '/something_strange';
    $output = MyApp::Dispatch->dispatch();
    contains_string($output, 'MyApp::Module::Name->rm1', 'override translate_module_name()');
}

BEGIN { $COUNT += 2 }

# cause errors
{

    # non-existant module
    local $ENV{PATH_INFO} = '/foo';
    $output = CGI::Application::Dispatch->dispatch();
    like($output, qr/Not Found/i);

    # not a valid path_info
    local $ENV{PATH_INFO} = '//';
    $output = CGI::Application::Dispatch->dispatch();
    like($output, qr/Internal Server Error/i);
}

BEGIN { $COUNT += 1 }

# args_to_new
{
    local $ENV{PATH_INFO} = '/module_name/rm4';
    $output = CGI::Application::Dispatch->dispatch(
        prefix      => 'MyApp',
        args_to_new => {PARAMS => {my_param => 'more testing'},},
    );
    contains_string(
        $output,
        'MyApp::Module::Name->rm3 my_param=more testing',
        'PARAMS passed through'
    );
}

BEGIN { $COUNT += 9 }

# use a full dispatch table in a subclass
{
    local $ENV{PATH_INFO} = '/module_name';
    $output = MyApp::DispatchTable->dispatch();
    contains_string($output, 'MyApp::Module::Name->rm1', 'matched :app');

    local $ENV{PATH_INFO} = '/module_name/rm2';
    $output = MyApp::DispatchTable->dispatch();
    contains_string($output, 'MyApp::Module::Name->rm2', 'matched :app/:rm');

    local $ENV{PATH_INFO} = '/module_name/rm3/stuff';
    $output = MyApp::DispatchTable->dispatch();
    contains_string(
        $output,
        'MyApp::Module::Name->rm3 my_param=stuff',
        'matched :app/:rm/:my_param'
    );

    local $ENV{PATH_INFO} = '/module_name/bar/stuff';
    $output = MyApp::DispatchTable->dispatch();
    contains_string(
        $output,
        'MyApp::Module::Name->rm3 my_param=stuff',
        'matched :app/bar/:my_param'
    );

    local $ENV{PATH_INFO} = '/foo/bar';
    $output = MyApp::DispatchTable->dispatch();
    contains_string($output, 'MyApp::Module::Name->rm2', 'matched foo/bar');

    local $ENV{PATH_INFO} = '/module_name/foo';
    $output = MyApp::DispatchTable->dispatch();
    contains_string($output, 'MyApp::Module::Name->rm3 my_param=', 'missing optional');

    local $ENV{PATH_INFO} = '/module_name/foo/weird';
    $output = MyApp::DispatchTable->dispatch();
    contains_string($output, 'MyApp::Module::Name->rm3 my_param=weird', 'present optional');

    local $ENV{PATH_INFO} = '/module_name/baz/this/is/extra';
    $output = MyApp::DispatchTable->dispatch();
    contains_string(
        $output,
        'MyApp::Module::Name->rm5 dispatch_url_remainder=this/is/extra',
        'url remainder'
    );

    local $ENV{PATH_INFO} = '/module_name/bap/this/is/extra';
    $output = MyApp::DispatchTable->dispatch();
    contains_string(
        $output,
        'MyApp::Module::Name->rm5 the_rest=this/is/extra',
        'named url remainder'
    );
}

BEGIN { $COUNT += 1 }

# local args_to_new
{
    local $ENV{PATH_INFO} = '/module_name/local_args_to_new';
    $output = CGI::Application::Dispatch->dispatch(
        prefix => 'MyApp',
        table  => [':app/:rm' => {args_to_new => {TMPL_PATH => 'events',},},],

    );
    contains_string($output, 'events', 'local args_to_new works');
}

BEGIN { $COUNT += 1 }

# 404
{
    local $ENV{PATH_INFO} = '/somewhere_else';
    $output = CGI::Application::Dispatch->dispatch(
        prefix => 'MyApp',
        table  => [':app/:rm' => {args_to_new => {TMPL_PATH => 'events',},},],

    );
    like_string(
        $output,
        qr/404 not found/i,
        "proper 404 error is returned when PATH_INFO isn't parsed."
    );
}

# restore STDERR
{
    close STDERR;
    open STDERR, ">&SAVE_ERR";
    close SAVE_ERR;
}

