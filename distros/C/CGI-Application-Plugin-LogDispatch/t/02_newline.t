use Test::More tests => 7;

use lib './t';
use strict;

$ENV{CGI_APP_RETURN_ONLY} = 1;

use TestAppNewline;
my $t1_obj = TestAppNewline->new();
my $t1_output = $t1_obj->run();

my $logoutput = ${$t1_obj->{__LOG_MESSAGES}->{HANDLE}};
my $logoutput_append = ${$t1_obj->{__LOG_MESSAGES}->{HANDLE_APPEND}};

like($logoutput, qr/log debug1/, 'logged debug message');
like($logoutput, qr/log info1/, 'logged info message');
like($logoutput, qr#log debug2$/#, 'newline manually added');
unlike($logoutput, qr#log debug1$/#, 'no automatic newline added');

unlike($logoutput_append, qr/log debug1/, 'no debug message');
like($logoutput_append, qr/log info1/, 'logged info message');
like($logoutput_append, qr#log info1$/#, 'newline automatically added');


