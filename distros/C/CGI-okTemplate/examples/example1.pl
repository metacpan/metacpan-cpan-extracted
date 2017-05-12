#!/use/bin/perl
use CGI::okTemplate;
my $tmpl = new CGI::Template(	File=>'templates/example1.tpl',
				BlockTag=>'Block');

$data = {
	header => 'value for "header" macro',
	footer => 'value for "footer" macro',
	row => [
		{value => 'value1',},
		{value => 'value2',},
		{value => 'value3',},
	],
};
