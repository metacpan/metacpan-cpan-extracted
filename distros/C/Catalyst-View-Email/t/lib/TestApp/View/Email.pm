package # Hide from PAUSE
    TestApp::View::Email;


use base 'Catalyst::View::Email';

__PACKAGE__->config(
    sender => {
        mailer => 'Test'
    },
);

1;
