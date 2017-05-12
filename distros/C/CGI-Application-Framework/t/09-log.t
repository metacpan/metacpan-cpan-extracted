use strict;
use Test::More 'no_plan';
use lib 't';
use CGI;

unlink 't/logs/webapp.log';

{
    package MyTestApp;

    use base 'TestApp';
    use TestCDBI;

    sub setup {
        my $self = shift;
        $self->run_modes([ qw(main_display) ]);
        $self->SUPER::setup();
    }

    sub main_display {
        my $self    = shift;
        my $stash = $self->stash;

        $self->log->emerg("Danger, Will Robinson!");

        $stash->{'Seen_Run_Mode'}{'main_display'} = 1;
        $stash->{'Final_Run_Mode'}                = 'main_display';
        '';
    }

}

# Set up query and app
my ($query, $app);
$query = new CGI;
$query->param('come_from_rm', 'login');
$query->param('current_rm',   'login');
$query->param('rm',           'main_display');


#######################################################################
# Fake that we've come from the login page with good parameters
$app   = MyTestApp->new(QUERY => $query);
$query->param('username',     'test');
$query->param('password',     'seekrit');
$app->run;

ok($app->stash->{'Password_OK'},                       '[login, good parms] valid password');
ok($app->stash->{'User_OK'},                           '[login, good parms] valid user');

open my $fh, 't/logs/webapp.log';

my $contents = join '', <$fh>;
like($contents, qr/Danger, Will Robinson!/, 'log output good');





