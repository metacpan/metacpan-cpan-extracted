use ExtUtils::MakeMaker;
# See ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'          => 'Array::Utils',
	'VERSION_FROM'  => 'Utils.pm',
	'ABSTRACT_FROM' => 'Utils.pm',
	($] >= 5.007003 ?    ## Add these new keywords supported since 5.005
		(AUTHOR     => 'Sergei A. Fedorov <zmij@cpan.org>') : ()),
);
