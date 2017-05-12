package Apache::RSS;

use ExtUtils::MakeMaker;
use lib './lib';
use Apache::RSS;
use Apache::src ();
use Apache::ExtUtils qw(command_table);

my @directives = (
    { 
	name => 'RSSEnableRegexp',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSChannelTitle',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSChannelDescription',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSCopyRight',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSEncoding',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSLanguage',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSScanHTMLTitle',
	args_how => 'FLAG',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSHTMLRegexp',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    { 
	name => 'RSSEncodeHandler',
	args_how => 'TAKE1',
	req_override => 'OR_INDEXES',
    },
    {
	name => 'RSSOrderBy',
	args_how => 'TAKE12',
	req_override => 'OR_INDEXES',
    }
);

__PACKAGE__->command_table(\@directives);

WriteMakefile(
    'NAME'      => __PACKAGE__,
    'VERSION_FROM' => 'lib/Apache/RSS.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	XML::RSS => 0.97,
	Time::Piece => 1.01,
    },
    PMLIBDIRS => ['lib'],
    INC => Apache::src->new->inc,
);
