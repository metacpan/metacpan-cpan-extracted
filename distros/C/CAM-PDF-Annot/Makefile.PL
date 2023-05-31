use strict;
use warnings;
use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %conf = (
    NAME              => 'CAM::PDF::Annot',
    VERSION_FROM      => 'lib/CAM/PDF/Annot.pm', # finds $VERSION
    PREREQ_PM => {
        'CAM::PDF'   => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CAM/PDF/Annot.pm', # retrieve abstract from module
       AUTHOR         => 'DONATOAZ <donatoaz@gmail.com>') : ()),
	clean => {FILES => 't/merged_pdf.pdf t/merged_multi_pdf.pdf'},
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
	$conf{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/szabgab/CAM-PDF-Annot.git',
				web  => 'https://github.com/szabgab/CAM-PDF-Annot',
			},
            bugtracker => {
                web => 'https://github.com/szabgab/CAM-PDF-Annot/issues'
            },
		}
	};
}

my %test_requires = (
    'Test::More' => 0,
    'YAML::Tiny' => 0,
);

if (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
	$conf{TEST_REQUIRES} = \%test_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %test_requires);
}

WriteMakefile(%conf);

