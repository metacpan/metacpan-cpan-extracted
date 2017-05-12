use strict;
use warnings; 

use Config;

use Test::More tests => 14;

use CGI::Test;

use constant WINDOWS => eval { $^O =~ /Win32|cygwin/ };

$ENV{PATH} = $Config{bin} . (WINDOWS ? ';' : ':') . $ENV{PATH};

my $BASE = "http://server:18/cgi-bin";
my $SCRIPT = WINDOWS ? "getform.bat" : "getform";

my $ct = CGI::Test->new(
	-base_url	=> $BASE,
	-cgi_dir	=> "t/cgi",
);

ok defined $ct, "Got CGI::Test object";
isa_ok $ct, 'CGI::Test', 'isa';

my $page = $ct->GET("$BASE/$SCRIPT");

ok $page->is_ok, "Page 1 OK";
ok !$page->is_error, "Page 1 error code " . $page->error_code;

my $form = $page->forms->[0];

is $form->method, 'GET', "Page 1 form method";

my @submit = $form->submits_named("Send");

is @submit, 1, "Number of Send submits in page 1";

my $months = $form->widget_by_name("months");
$months->select("Jan");

my $send = $form->submit_by_name("Send");
my $page2 = $send->press;

ok !$page2->is_error, "Page 2 error code " . $page2->error_code;
is $page2->form_count, 1, "Page 2 form count";

my $form2 = $page2->forms->[0];
@submit = $form2->submits_named("Send");

is @submit, 1, "Number of Send submits in page 2";
is $form2->method, 'GET', "Form 2 method";
like $form2->enctype, qr/urlencoded/, "Form 2 encoding";

my $months2 = $form2->widget_by_name("months");

ok $months2->is_selected("Jul"), "Form 2 Jul is selected";
ok $months2->is_selected("Jan"), "Form 2 Jan is selected";
ok !$months2->is_selected("Feb"), "Form 2 Feb is not selected";

