package Apache::CustomKeywords;
use strict;
use ExtUtils::MakeMaker;
use Apache::src;
use Apache::ExtUtils qw(command_table);

command_table([
    {
	name => 'CustomKeyword',
	errmsg => 'keyword and URL for search engine',
	args_how => 'TAKE2',
	req_override => 'OR_ALL',
    },
]);

WriteMakefile(
    'NAME'         => __PACKAGE__,
    'VERSION_FROM' => 'lib/Apache/CustomKeywords.pm', # finds $VERSION
    'INC'          => Apache::src->new->inc,
    'PREREQ_PM'    => {
	'Test::More' => 0.32,
	'mod_perl' => 1.20,
    },
    'clean'        => {
	FILES => '*.xs*',
    },
);
