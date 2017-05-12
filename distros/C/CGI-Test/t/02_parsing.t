use strict; 
use warnings; 

use Config;
use URI;

use Test::More tests => 49;

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
my $raw_length = length $page->raw_content;

ok $page->is_ok, "Page OK";
ok !$page->is_error, "No errors in page " . $page->error_code;

ok $raw_length, "Got raw content length: $raw_length";

my $content_length = $page->content_length;
is $content_length, $raw_length, "Page content-length matches";

my $headers = $page->headers;

is 'HASH', ref($headers), "Headers hashref defined";
ok exists $headers->{'Content-Type'}, "Content-Type header exists in hashref";

$content_length = $page->header('CoNtEnT-LenGTh');
is $content_length, $raw_length, "Header content-length matches";

my $content_type = $page->header('content-type');
like $content_type, qr|^text/html\b|, "Header Content-Type matches";

like $page->content_type, qr|^text/html\b|, "Page content type matches";

my $forms = $page->forms;

cmp_ok @$forms, '==', 1, "Number of forms";

my $form = $forms->[0];

my $rg = $form->radio_groups;
my @names = $rg->names;

ok $rg, "Radio groups defined";
is @names, 1, "Number of radio groups";

my $r_groupname = $names[0];

ok $rg->is_groupname($r_groupname), "Got radio group name: $r_groupname";

my @buttons = $rg->widgets_in($r_groupname);

is @buttons, 3, "Number of buttons in radio group";
is $rg->widget_count($r_groupname), 3, "Number of widgets in radio group";

my $cg = $form->checkbox_groups;
@names = $cg->names;

ok $cg, "Checkbox groups defined";
is @names, 2, "Number of checkbox groups";

my $c_groupname = "skills";

ok $cg->is_groupname($c_groupname), "Got checkbox group name: $c_groupname";

@buttons = $cg->widgets_in($c_groupname);

is @buttons, 4, "Number of buttons in cbox group";
is $cg->widget_count($c_groupname), 4, "Number of widgets in cbox group";

# 1 of each: field, area, passwd, file
my @wants = qw/ 4 4 2 5 /;
for my $type ( qw/ inputs buttons menus checkboxes / ) {
    my $want = shift @wants;
    my $have = $form->$type;

    is @$have, $want, "Number of $type in form";
}

my $months = $form->menu_by_name("months");

ok defined $months, "Months menu defined";
ok !$months->is_popup, "Months menu is not popup";
is $months->selected_count, 1, "Months menu selected count";
is @{$months->option_values}, 12, "Months menu option values";
ok $months->is_selected("Jul"), "Months menu Jul is selected";
ok !$months->is_selected("Jan"), "Months menu Jan is not selected";

my $color = $form->menu_by_name("color");

ok  defined $color, "Color menu defined";
ok $color->is_popup, "Color menu is popup";
ok $color->is_selected("white"), "Color menu implicit selection";
is $color->selected_count, 1, "Color menu selected count";
is $color->option_values->[0], "white", "Color menu option value";
ok !$color->is_selected("black"), "Color menu black is not selected";

my @menus = $form->widgets_matching(sub { $_[0]->is_menu });

is @menus, 2, "Number of menus";

my @radio = $form->radios_named("title");

is @radio, 3, "Number of title radios";

is( URI->new($form->action)->path, "/cgi-bin/$SCRIPT", "Script path" );
is $form->method, "GET", "HTTP method";
is $form->enctype, "application/x-www-form-urlencoded", "Encoding";

my @submit = grep { $_->name !~ /^\./ } $form->submit_list;

is @submit, 2, "Number of submit buttons";

@buttons = $cg->widgets_in("no-such-group");

is @buttons, 0, "Number of buttons in no-such-group";
is $cg->widget_count("no-such-group"), 0, "Number of widgets in no-such-group";

my $new = $form->checkbox_by_name("new");

ok defined $new, "New checkbox defined";
ok $new->is_checked, "New checkbox is checked";
ok $new->is_standalone, "New checkbox is standalone";

