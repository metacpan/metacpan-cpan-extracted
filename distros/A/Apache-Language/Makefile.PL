package Apache::Language;

use strict;
use Apache::src ();
use Apache::ExtUtils qw(command_table);
use ExtUtils::MakeMaker;

my $class = __PACKAGE__;
my $module = "Language";

my @directives = (
	{   name        =>  'LanguageHandler',
        errmsg      =>  'One or more perl Module',
        args_how    =>  'RAW_ARGS',
        req_override=>  'OR_ALL',
    },
    {   name        =>  'LanguageDefault',
        errmsg      =>  'One or more language tags',
        args_how    =>  'ITERATE',
        req_override=>  'OR_ALL',
    },
    {   name        =>  'LanguageForced',
        errmsg      =>  'One or more language tags',
        args_how    =>  'ITERATE',
        req_override=>  'OR_ALL',
    },
    {   name        =>  'LanguageDebug',
        errmsg      =>  'Debug level (integer)',
        args_how    =>  'TAKE1',
        req_override=>  'RSRC_CONF',
    },
    {   name        =>  'DefaultLanguage',
        errmsg      =>  'One language tag',
        args_how    =>  'RAW_ARGS',
        req_override=>  'OR_ALL',
    },
);

command_table \@directives;

WriteMakefile(
	'NAME'	  	    => $class,
	'VERSION_FROM'	=> "$module.pm",            
	'INC'		    => Apache::src->new->inc,
	'PREREQ_PM'	    => {
                    'Apache'            => 0,
                    'I18N::LangTags'    => 0.11,
				    }, 
);

sub MY::dist {
    system "pod2text $module.pod > README";
    shift->MM::dist;
}

