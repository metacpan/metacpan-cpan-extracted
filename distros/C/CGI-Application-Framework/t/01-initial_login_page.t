
use strict;
use Test::More 'no_plan';
use lib 't';

my $Shown_Login_Page = 'false';

{
    package MyTestApp;

    use base 'TestApp';
    use TestCDBI;

    sub setup {
        my $self = shift;
        $self->run_modes([ qw(main_display) ]);
        $self->header_type('none');
    }

    sub main_display {
        my $self = shift;
        '';
    }
    sub login {
        my $self = shift;
        $Shown_Login_Page = 'true';
        '';
    }
}

my $app = MyTestApp->new;

is(ref $app, 'MyTestApp', 'MyTestApp loaded okay');
is($Shown_Login_Page, 'false', 'not shown login page yet');

$app->run;

is($Shown_Login_Page, 'true', 'displayed login page');



