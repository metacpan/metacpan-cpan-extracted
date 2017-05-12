require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Bundle::Devel',
	'VERSION_FROM' => 'lib/Bundle/Devel.pm',
	'PREREQ_PM'    => {
		'Devel::DProf'    => 0,
		'Devel::Cover'    => 0,
		'Devel::Coverage' => 0,
		'Devel::Profile'  => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'     => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT'   => 'Bundle file for the most common devel modules',
	) : (),
);
