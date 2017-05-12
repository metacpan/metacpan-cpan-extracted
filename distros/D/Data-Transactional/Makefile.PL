use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Data::Transactional',
    META_MERGE => {
        license => 'other',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Data-Transactional',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Data-Transactional/issues'
        }
    },
    VERSION_FROM => 'lib/Data/Transactional.pm',
    PREREQ_PM    => {
	'Scalar::Util'     => 0,
        Storable           => 2.07,  # we use dclone()
        'Data::Compare'    => 0.11,  # used for testing,
                                     # and by D:C:Plugins:D:T
        }
);
