#!/usr/bin/perl -w
use Test::Simple tests => 5;
use Cwd;
use lib './lib';
use CGI::Session::Submitted;
#use Smart::Comments '###';

$ENV{SCRIPT_NAME} = cwd().'/t/basic.t';
$ENV{DOCUMENT_ROOT} = cwd().'/public_html';


my $css = new CGI::Session::Submitted;
$css->run({
	help_on => 5,
	last_name => undef,
},
{
	nocookie => 1,
}
);

ok($css, 'module loaded');

my $id = $css->id;
ok($id, "id $id");


my $presets = $css->get_presets;
### $presets

ok($presets,'presets array');


ok($css->param('help_on') == 5, 'param ok');
ok( !$css->param('last_name'), 'param ok');

