package MyApp::DispatchRest;
use base 'CGI::Application::Dispatch';

sub dispatch_args {
    return {
        auto_rest => 1,
        prefix    => 'MyApp',
        table     => [
            ':app/rm3[get]' => { rm => 'get_rm3', auto_rest => 0 },
            ':app/rm4'      => { auto_rest => 0, rm => 'rm4' },
            ':app/rm2'      => { auto_rest_lc => 1, rm => 'rm2' },
            ':app/:rm'      => { },
        ],
    };
}

1;
