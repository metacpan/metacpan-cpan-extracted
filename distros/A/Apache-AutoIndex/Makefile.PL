package Apache::AutoIndex;

use strict;
use Apache::src ();
use Apache::ExtUtils qw(command_table);
use ExtUtils::MakeMaker;

my $class = __PACKAGE__;

my @directives = (
	{	name		=> 'IndexIgnore',
		func		=> 'push_config',
		cmd_data	=> 'ignore',
		errmsg		=> 'a list of file names',
		args_how	=> 'ITERATE',
		req_override	=> 'OR_INDEXES',
	},
	{	name		=> 'DirectoryIndex',
		errmsg		=> 'one or more file extensions',
		args_how	=> 'ITERATE',
		req_override	=> 'OR_INDEXES',
	},
	{	name		=> 'HeaderName',
		func		=> 'push_config',
		cmd_data	=> 'header',
		errmsg		=> 'a list of file names',
		args_how	=> 'ITERATE',
		req_override	=> 'OR_INDEXES',
	},
	{	name		=> 'ReadmeName',
		func		=> 'push_config',
		cmd_data	=> 'readme',
		errmsg		=> 'a list of file names',
		args_how	=> 'ITERATE',
		req_override	=> 'OR_INDEXES',
	},
	{	name		=> 'FancyIndexing',
		errmsg		=> 'Limited to on or off (superseded by IndexOptions FancyIndexing)',
		args_how	=> 'FLAG',
		req_override	=> 'OR_INDEXES',
	},
	{	name		=> 'IndexOrderDefault',
		errmsg		=> '{Ascending,Descending} {Name,Size,Description,Date}',
		args_how	=> 'TAKE2',
		req_override	=> 'OR_INDEXES',
	},
	{	name		=> 'AddDescription',
		errmsg		=> 'Descriptive text followed by one or more filenames',
		args_how	=> 'RAW_ARGS',
		req_override	=> 'OR_INDEXES',
	},
	{	name		=> 'IndexOptions',
		errmsg		=> 'one or more index options',
		args_how	=> 'RAW_ARGS',
		req_override	=> 'OR_INDEXES',
	},
	
);

command_table \@directives;

WriteMakefile(
	'NAME'	  	=> $class,
	'VERSION_FROM'	=> "AutoIndex.pm",        
	'INC'		=> Apache::src->new->inc,
	'PREREQ_PM'	=> { 
				'Apache::Icon'  => '0.02',   
				'HTML::HeadParser' => 0,
			     	'Apache'        => 0,
				'Apache::Status' => 0,
				'Apache::Language' => 0,
			   	'Storable'	=> 0,
				}, 
);
