use strict;
use Test::More 'no_plan';
use lib 't';
use CGI;

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

        my $template = $self->template->load;
        $self->conf->context->{'output_file_name_comment'} = 1;

        $template->param(
            var1 => 'value_one',
            var2 => 'value_two',
            var3 => 'value_three',
        );
        my $output = $template->output;

        $output = $$output if ref $output eq 'SCALAR';
        $stash->{'Template_Filename'} = $template->filename;
        $stash->{'Template_Output'} = $output;
        $stash->{'Seen_Run_Mode'}{'main_display'} = 1;
        $stash->{'Final_Run_Mode'}                = 'main_display';
        '';
    }
    sub _make_hidden_session_state_tag {
        'a session session session'
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

# The check for SESSION_STATE is there to make sure that the
# template_pre_process callback ran correctly

my $template_filename = $app->stash->{'Template_Filename'};

my $expected_output = qq{<!-- begin template file [[$template_filename]] -->--begin--
SESSION_STATE:a session session session
var1:value_one
var2:value_two
var3:value_three
--end--
<!-- end template file [[$template_filename]] -->};

ok($app->stash->{'User_OK'},                           '[login, good parms] valid user');
ok($app->stash->{'Password_OK'},                       '[login, good parms] valid password');
like($template_filename, qr/main_display\.html$/,      '[login, good parms] template->filename');
is($app->stash->{'Template_Output'}, $expected_output, 'template output good');





