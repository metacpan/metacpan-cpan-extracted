
use strict;
use Test::More tests => 2;

$ENV{CAP_DEVPOPUP_EXEC} = 1;

eval "require ValidateApp";

SKIP: {
    if($@ =~ /DevPopup/ ) {
        skip "CAP::DevPopup not installed, won't generate validation reports without it", 2;
    }

    use lib './t';

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    $ENV{REQUEST_METHOD} = 'GET';
    my $app = ValidateApp->new;

    like($app->run, qr/valid/, 'valid html');

    my $app2 = ValidateApp->new();
    $app2->start_mode('invalid_html');

    like ($app2->run, qr/missing .*DOCTYPE.* declaration/ , 'First error message');
}

