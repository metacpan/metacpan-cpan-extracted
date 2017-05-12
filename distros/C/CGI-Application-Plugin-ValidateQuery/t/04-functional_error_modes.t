use Test::More 'no_plan';

use strict;
use warnings;

{
    package TestApp;
    use FindBin '$Bin';
    use lib "$Bin/../lib";

    use base 'CGI::Application';
    use CGI::Application::Plugin::ValidateQuery ':all';

    sub setup {
        my $self = shift;
        $self->start_mode('index');
        $self->run_modes(
            index=>'index',
            error=>'error'
        );
        $self->validate_query_config();
    }

    sub index {
        my $self = shift;
        use CGI;
        $self->query(CGI->new('one=1&two=two&three=2&three=3'));
        $self->validate_query(
            one   => { type=>ARRAYREF, optional=>0 },
            two   => { type=>SCALAR,   optional=>0 },
            three => { type=>ARRAYREF, optional=>0 }
        );
    }

    sub error {
        my $self = shift;
        return "<html><head><title>Something has gone
                wrong</title></head><body>Please stand by!</body></html>";
    }    
}

$ENV{CGI_APP_RETURN_ONLY} = 1;

like(TestApp->new->run(),qr/not be understood/,'Failed validation, default rm');

my $app = TestApp->new();

$app->validate_query_config(
    error_mode=>'error'
);    

like($app->run(), qr/stand by/, 'Failed validation, custom rm');
