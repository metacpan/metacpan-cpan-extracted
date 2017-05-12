package Apache::Imager::Resize;

use ExtUtils::MakeMaker;
use Apache::ExtUtils qw(command_table);
use Apache::src ();

command_table([
	{ 
		name     => 'ImgResizeNoCache',
		errmsg   => 'If true, the image cache is disabled.',
		args_how => 'FLAG',
		req_override => 'RSRC_CONF|ACCESS_CONF'
	}, 
	{ 
		name     => 'ImgResizeCacheDir',
		errmsg   => 'The (optional) directory that will be used for the cache of resized image files.',
		args_how => 'TAKE1',
		req_override => 'RSRC_CONF|ACCESS_CONF'
	}, 
	{ 
		name     => 'ImgResizeWidthParam',
		errmsg   => 'The (optional) name of the width parameter.',
		args_how => 'TAKE1',
		req_override => 'RSRC_CONF|ACCESS_CONF'
	}, 
	{ 
		name     => 'ImgResizeHeightParam',
		errmsg   => 'The (optional) name of the height parameter.',
		args_how => 'TAKE1',
		req_override => 'RSRC_CONF|ACCESS_CONF'
	}, 
]);

WriteMakefile(
    NAME           => 'Apache::Imager::Resize',
    VERSION_FROM   => 'lib/Apache/Imager/Resize.pm',
    INC            => Apache::src->new->inc,
    PREREQ_PM      => {
		Imager => 0,
		Apache => 1,
		File::Basename => 0,
	},
    AUTHOR         => 'William Ross <wross@cpan.org>',
    clean => { 
        FILES => './Resize.xs.orig' 
    },
);
