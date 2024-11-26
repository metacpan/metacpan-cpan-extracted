use Test::More tests => 9;
use File::Spec;
BEGIN { use_ok('CGI::Application::Plugin::Session') };

use lib './t';
use strict;
use warnings;

{
    package TestAppOptions;
    @TestAppOptions::ISA = qw(CGI::Application);
    use CGI::Application::Plugin::Session;
};

my $t1_obj = TestAppOptions->new();
$t1_obj->session_config(
    CGI_SESSION_OPTIONS => [ "driver:File", $t1_obj->query ],
    SEND_COOKIE         => 1,
    DEFAULT_EXPIRY      => '+1y',
    COOKIE_PARAMS       => { -domain => 'example.com' },
);

ok($t1_obj->{__CAP__SESSION_CONFIG}->{CGI_SESSION_OPTIONS}, 'CGI_SESSION_OPTIONS defined');
ok($t1_obj->{__CAP__SESSION_CONFIG}->{SEND_COOKIE}, 'SEND_COOKIE defined');
ok($t1_obj->{__CAP__SESSION_CONFIG}->{DEFAULT_EXPIRY}, 'DEFAULT_EXPIRY defined');
ok($t1_obj->{__CAP__SESSION_CONFIG}->{COOKIE_PARAMS}, 'COOKIE_PARAMS defined');

my $session = $t1_obj->session;
my $session_id = $session->id;
eval {
    $t1_obj->session_config(
        CGI_SESSION_OPTIONS => [ "driver:File", $t1_obj->query ],
        SEND_COOKIE         => 1,
        DEFAULT_EXPIRY      => '+1y',
        COOKIE_PARAMS       => { -domain => 'example.com' },
    );
};
like($@, qr/Calling session_config after the session has already been created/, 'Can not call config_session after session created');

eval {
    $t1_obj = TestAppOptions->new();
    $t1_obj->session_config(
        CGI_SESSION_OPTIONS => 'invalid',
    );
};
like($@, qr/session_config error:  parameter CGI_SESSION_OPTIONS is not an array reference/, 'CGI_SESSION_OPTIONS should be an arrayref');

eval {
    $t1_obj = TestAppOptions->new();
    $t1_obj->session_config(
        COOKIE_PARAMS => 'invalid',
    );
};
like($@, qr/session_config error:  parameter COOKIE_PARAMS is not a hash reference/, 'COOKIE_PARAMS should be a hashref');

eval {
    $t1_obj = TestAppOptions->new();
    $t1_obj->session_config(
        INVALID_OPTION => 'invalid',
    );
};
like($@, qr/Invalid option\(s\)/, 'invalid option');

undef $t1_obj;
undef $session;
unlink File::Spec->catdir('t', 'cgisess_'.$session_id);

