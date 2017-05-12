package MyApp::DispatchTable;
use base 'CGI::Application::Dispatch';

sub dispatch_args {
    return {
        prefix  => 'MyApp',
        table   => [
            'foo/bar'             => { app => 'Name', rm => 'rm2', prefix => 'MyApp::Module' },
            ':app/bar/:my_param'  => { rm => 'rm3' },
            ':app/foo/:my_param?' => { rm => 'rm3' },
            ':app/baz/*'          => { rm => 'rm5' },
            ':app/bap/*'          => { rm => 'rm5', '*' => 'the_rest' },
            ':app/:rm/:my_param'  => { },
            ':app/:rm'            => { },
            ':app'                => { },
            ''                    => { app => 'Module::Name', rm => 'rm1' },
        ],
        args_to_new => {
            PARAMS => { hum => 'electra_2000' },
        },
    };
}

1;
