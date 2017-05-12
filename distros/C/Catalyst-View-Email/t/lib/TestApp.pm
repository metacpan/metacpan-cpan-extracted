package # Hide from PAUSE
    TestApp;

use Catalyst;
use FindBin;

TestApp->config(
    root            => "$FindBin::Bin/root",
    default_view    => 'TT',
    'View::Email::AppConfig' => {
        sender => {
            mailer => 'Test',
        },
    },
    'View::Email::Template::AppConfig' => {
        stash_key => 'template_email',
        sender => {
            mailer => 'Test',
        },
		content_type => 'text/html',
        default => {
            view => 'TT',
        },
    },
);

TestApp->setup;

1;
