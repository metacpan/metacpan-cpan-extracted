use ExtUtils::MakeMaker;
use Test::More;

die "FATAL ERROR: Can only run on AIX" unless ( $^O eq 'aix' );

WriteMakefile(
	'NAME'		=> 'AIX::SysInfo',
	'VERSION_FROM'	=> 'SysInfo.pm',
	'AUTHOR'	=> 'Sergey Leonovich <sleonov@cpan.org>',
);
