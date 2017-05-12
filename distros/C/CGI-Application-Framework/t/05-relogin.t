
use strict;
use Test::More 'no_plan';
use lib 't';
use CGI;
use URI;

my $Consistency_Match;

{
    package MyTestApp;

    use base 'TestApp';
    use TestCDBI;

    sub setup {
        my $self = shift;
        $self->run_modes([ qw(main_display page_the_second) ]);

        $self->SUPER::setup();
    }

    sub _relogin_profile {
        return {
            required => [ qw ( password ) ],
            msgs     => {
                any_errors => 'some_errors', # just want to set a true value here
                prefix     => 'err_',
            },
        };
    }
    sub _relogin_authenticate {
        my $self     = shift;

        my $user = undef;
        $user = TestCDBI::Users->retrieve(
            $self->session->{uid}
        );

        if ($user) {
            $self->stash->{'User_OK'} = 1;
        }
        ($self->stash->{'Password_OK'}, $user) = $self->_password_authenticate_user($user);
        return ($self->stash->{'Password_OK'}, $user);
    }
    sub _relogin_failed_errors {
        my $self = shift;

        my $is_login_authenticated = shift;
        my $user = shift;
        my $errs = undef;

        if ( $user && (!$is_login_authenticated) ) {
            $errs->{'err_password'} = 'Incorrect password for this user';
        }
        else {
            die "Can't happen! ";
        }
        $errs->{some_errors} = '1';

        return $errs;
    }

    sub relogin {
        my $self = shift;

        $self->stash->{'Seen_Run_Mode'}{'relogin'} = 1;
        $self->stash->{'Final_Run_Mode'}           = 'relogin';

        # When login is run via ValidateRM, we have to return text to
        # indicate to the Framework that we actually ran the login page

        # When login is run directly, we can't return text or we'll screw
        # up the tests

        return $self->stash->{'Suppress_Output'} ? '' : 'relogin page yada yada yada';
    }

    sub _relogin_test {
        my $self = shift;

        if ($self->session->{'consistency'} =~ $Consistency_Match) {
            return 1;
        }
        else {
            return;
        }

    }
    sub page_the_second {
        my $self = shift;
        $self->stash->{'Seen_Run_Mode'}{'page_the_second'} = 1;
        $self->stash->{'Final_Run_Mode'}                   = 'page_the_second';
        '';
    }
}

#######################################################################
# Subclass with a custom _relogin_profile requiring an extra organic banana
# and a password longer than four chars.

{
    package MyTestApp_custom_login_profile;

    use base 'MyTestApp';
    sub _relogin_profile {
        return {
            required     => [ qw ( password banana ) ],
            constraints  => {
                banana   => qr/organic/i,
                password => qr/...../,   # at least five chars
            },
            msgs     => {
                any_errors => 'some_errors', # just want to set a true value here
                prefix     => 'err_',
            },
        };
    }

}

#######################################################################
# Subclass with a custom _login_authenticate that ignores the username
# and password and always returns the user 'bubba'
{
    package MyTestApp_custom_login_authenticate;

    use base 'MyTestApp';

    # This strange _login_authenticate sub always returns the user 'bubba'
    sub _login_authenticate {
        my $self = shift;
        my ($user) = TestCDBI::Users->search(
            username => 'bubba',
        );

        if ($user) {
            $self->stash->{'User_OK'}     = 1;
            $self->stash->{'Password_OK'} = 1;
        }

        return (1, $user);
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

ok($app->stash->{'User_OK'},                          '[login, good parms] valid user');
ok($app->stash->{'Password_OK'},                      '[login, good parms] valid password');

my $session_id;
if ($app->stash->{'Cookie'} =~ m{^\s*session_id=(\S*);\s+path=/\s*$}i ) {
    $session_id = $1;
}

like($session_id, qr/^[a-fA-F0-9]+$/, '[login, good parms] Session looks valid');

is($app->session->{username}, 'test', '[login, good parms] user is test');
is($app->session->{wubba},    'yes',  '[login, good parms] session value wubba');

$app->session->{'consistency'} =   'the goblin of little minds';
is($app->session->{'consistency'}, 'the goblin of little minds',  '[login, good parms] stored session value consistency');

ok($app->stash->{'Seen_Run_Mode'}{'main_display'},  '[login, good parms] fall through to main_display');
is($app->stash->{'Final_Run_Mode'}, 'main_display', '[login, good parms] final page was main_display');

my $link = $app->make_link(
    qs_args => {
        rm => 'page_the_second',
    }
);

#######################################################################
# link from main_display to page_the_second

$Consistency_Match = qr/goblin/;

my $uri = URI->new($link);
my %link_param = $uri->query_form;

$query = new CGI;
$query->param($_, $link_param{$_}) for keys %link_param;

$app   = MyTestApp->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'page_the_second'},  '[page_the_second, pass _relogin_test] fall through to page_the_second');
is($app->stash->{'Final_Run_Mode'}, 'page_the_second', '[page_the_secondpass _relogin_test] final page was page_the_second');


#######################################################################
# link from main_display to page_the_second, but fail consistency check

$Consistency_Match = qr/hobgoblin/;
$query = new CGI;
$query->param($_, $link_param{$_}) for keys %link_param;


$app   = MyTestApp->new(QUERY => $query);
$app->stash->{'Suppress_Output'} = 1;
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},  '[page_the_second, fail _relogin_test] redirected to relogin');
is($app->stash->{'Final_Run_Mode'}, 'relogin', '[page_the_second, fail _relogin_test] final page was relogin');

undef $app->stash->{'Suppress_Output'};


$Consistency_Match = qr/goblin/;



#######################################################################
# relogin submitted, did not successfully reauthenticate (bad form profile)

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     '');

$app   = MyTestApp->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},      '[relogin sub to page_the_second, fail - bad profile] redisplay relogin form');
is($app->stash->{'Final_Run_Mode'}, '_echo_page',  '[relogin sub to page_the_second, fail - bad profile] redisplay relogin form via echo_page');



#######################################################################
# relogin submitted, did not successfully reauthenticate (bad password)

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     'borgel');


$app   = MyTestApp->new(QUERY => $query);
$app->stash->{'Suppress_Output'} = 1;
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},   '[relogin sub to page_the_second, fail - bad password] redisplay relogin form');
is($app->stash->{'Final_Run_Mode'}, 'relogin',  '[relogin sub to page_the_second, fail - bad password] landed on redisplay relogin form');

undef $app->stash->{'Suppress_Output'};


#######################################################################
# relogin submitted, did not successfully reauthenticate (custom profile 1)

$Consistency_Match = qr/goblin/;

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     'seek');

$app   = MyTestApp_custom_login_profile->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},      '[relogin sub to page_the_second, fail - bad custom profile (short password, no banana)] redisplay relogin form');
is($app->stash->{'Final_Run_Mode'}, '_echo_page',  '[relogin sub to page_the_second, fail - bad custom profile (short password, no banana)] redisplay relogin form via echo_page');


#######################################################################
# relogin submitted, did not successfully reauthenticate (custom profile 2)

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     'seekrit');

$app   = MyTestApp_custom_login_profile->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},      '[relogin sub to page_the_second, fail - bad custom profile (no banana)] redisplay relogin form');
is($app->stash->{'Final_Run_Mode'}, '_echo_page',  '[relogin sub to page_the_second, fail - bad custom profile (no banana)] redisplay relogin form via echo_page');


#######################################################################
# relogin submitted, did not successfully reauthenticate (custom profile, bad password)

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     'seek');
$query->param('banana',       'One Genuine Organic Banana');


$app   = MyTestApp_custom_login_profile->new(QUERY => $query);
$app->stash->{'Suppress_Output'} = 1;
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},   '[relogin sub to page_the_second, fail - custom profile passed, but bad password] redisplay relogin form');
is($app->stash->{'Final_Run_Mode'}, 'relogin',  '[relogin sub to page_the_second, fail - custom profile passed, but bad password] landed on redisplay relogin form');

undef $app->stash->{'Suppress_Output'};

#######################################################################
# relogin submitted, successfully reauthenticated (custom profile)

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     'seekrit');
$query->param('banana',       'One Genuine Organic Banana');

$app   = MyTestApp_custom_login_profile->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'page_the_second'},  '[relogin sub to page_the_second, pass, custom profile] fall through to page_the_second');
is($app->stash->{'Final_Run_Mode'}, 'page_the_second', '[relogin sub to page_the_second, pass, custom profile] final page was page_the_second');


#######################################################################
# fail consistency check again
# TODO: the system should allow a second relogin without hosing the user's session.
# (e.g. the user might hit the back button and retype their password)

$Consistency_Match = qr/hobgoblin/;
$query = new CGI;
$query->param($_, $link_param{$_}) for keys %link_param;


$app   = MyTestApp->new(QUERY => $query);
$app->stash->{'Suppress_Output'} = 1;
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},  '[page_the_second, fail _relogin_test] redirected to relogin');
is($app->stash->{'Final_Run_Mode'}, 'relogin', '[page_the_second, fail _relogin_test] final page was relogin');

undef $app->stash->{'Suppress_Output'};

$Consistency_Match = qr/goblin/;


#######################################################################
# relogin submitted, successfully reauthenticated

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     'seekrit');

$app   = MyTestApp->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'page_the_second'},  '[relogin sub to page_the_second, pass] fall through to page_the_second');
is($app->stash->{'Final_Run_Mode'}, 'page_the_second', '[relogin sub to page_the_second, pass] final page was page_the_second');



#######################################################################
# Verify the integrity of a form posting through the relogin

$Consistency_Match = qr/hobgoblin/;

# Create a CGI query in a data file

# my $input = CGI::Test::Input::Multipart->new();
#
# $input->add_field("come_from_rm", "page_the_second");
# $input->add_field("rm",           "page_the_second");
# # $input->add_field("bork",         "bork\n\rfoo".chr(27)."beeble\n");
# $input->add_field("_session_id",  $session_id);
# $input->add_file("upfile",        "t/data/test_upload.txt");

# Ideas and code borrowed from Gabor Szabo's CGI::Upload test script
# and from CGI::Test::Input::Multipart by Raphael Manfredi and Steven Hilton

my $unusual_value = "bork\n\rfoo".chr(27)."beeble\r\n\r\nkowabunga";
my %form_params = (
    come_from_rm => 'page_the_second',
    rm           => 'page_the_second',
    _session_id  => $session_id,
    'unusual'    => $unusual_value,
);

my $boundary = "----------1234567890";

my $data = '';

foreach my $param (keys %form_params) {
    $data .= qq(--$boundary\r\n);
    $data .= qq(Content-Disposition: form-data; name="$param"\r\n);
    $data .= qq(\r\n);
    $data .= qq($form_params{$param});
    $data .= qq(\r\n);
}

my %files = (
    first_files => [qw(
        t/data/jabberwocky.txt
        t/data/walrus.txt
    )],
    second_files => [qw(
        t/data/snark.txt
    )],
);

my %file_contents;
foreach my $field_name (keys %files) {
    foreach my $fn (@{ $files{$field_name} }) {
        $data .= qq(--$boundary\r\n);
        $data .= qq(Content-Disposition: form-data; name="$field_name"; filename="$fn"\r\n);
        $data .= qq(Content-Type: text/plain\r\n);
        $data .= qq(\r\n);

        local $/;
        open my $fh, '<', $fn or die "can't open $fn";

        $file_contents{$fn} = <$fh>;

        $data .= qq($file_contents{$fn}\r\n);
    }
}

$data .= qq(--$boundary--\r\n);


open my $fh, '+>', 't/data/formdata' or die "Can't clobber t/data/formdata: $!\n";

print $fh "Content-Type: multipart/form-data; boundary=$boundary\015\012";
print $fh "Content-Length: ", length($data), "\015\012";
print $fh "\015\012";
print $fh $data;
seek $fh, 0, 0;

# Dup STDIN
open my $old_stdin, '>&', 'STDIN' or die "Can't dup STDIN: $!\n";
open STDIN, '>&', $fh or die "Can't redirect STDIN: $!\n" ;

$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'CONTENT_TYPE'}   = "multipart/form-data; boundary=$boundary";
$ENV{'CONTENT_LENGTH'} = -s 't/data/formdata';

$query = CGI->new;

ok(!$query->cgi_error, 'CGI object successfully created') or warn "CGI error: ". $query->cgi_error . "\n";

# restore STDIN
open STDIN, '>&', $old_stdin, or die "Can't restore STDIN: $!\n";

$app   = MyTestApp->new(QUERY => $query);
$app->stash->{'Suppress_Output'} = 1;
$app->run;
undef $app->stash->{'Suppress_Output'};

ok($app->stash->{'Seen_Run_Mode'}{'relogin'},  '[page_the_second, query test, fail _relogin_test] redirected to relogin');
is($app->stash->{'Final_Run_Mode'}, 'relogin', '[page_the_second, query test, fail _relogin_test] final page was relogin');

my %upload_contents;
{
    local $/;

    for my $field (qw(first_files second_files)) {
        my (@fh)        = $query->upload($field);
        my (@filenames) = $query->param($field);

        for (my $i = 0; $i < @fh; $i++) {
            my $handle = $fh[$i];
            $upload_contents{$filenames[$i]} = <$handle>;
        }
    }
}

for my $file (keys %file_contents) {
    is($upload_contents{$file}, $file_contents{$file}, "[initial query] upload file contents okay: $file");
}
is($query->param('unusual'), $unusual_value,           '[initial query] unusual value survived');


$Consistency_Match = qr/goblin/;

#######################################################################
# relogin submitted, successfully reauthenticated

$query = new CGI;
$query->param('_session_id',  $session_id);
$query->param('come_from_rm', 'relogin');
$query->param('rm',           'relogin');
$query->param('password',     'seekrit');

$app   = MyTestApp->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'page_the_second'},  '[relogin sub to page_the_second, pass] fall through to page_the_second');
is($app->stash->{'Final_Run_Mode'}, 'page_the_second', '[relogin sub to page_the_second, pass] final page was page_the_second');
is($query->param('unusual'), $unusual_value, '[relogin sub to page_the_second, pass] unusual value survived');

undef %upload_contents;
{
    local $/;

    for my $field (qw(first_files second_files)) {
        my (@fh)        = $query->upload($field);
        my (@filenames) = $query->param($field);

        for (my $i = 0; $i < @fh; $i++) {
            my $handle = $fh[$i];
            $upload_contents{$filenames[$i]} = <$handle>;
        }
    }
}

SKIP: {
    my $num_files = keys %file_contents;
    skip "CGI uploads don't currently survive the relogin process", $num_files;
    for my $file (keys %file_contents) {
        is($upload_contents{$file}, $file_contents{$file}, "[initial query] upload file contents okay: $file");
    }
}




