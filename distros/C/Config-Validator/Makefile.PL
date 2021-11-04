use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%param, $emv, $name);

%param = (
    NAME                   => 'Config::Validator',
    AUTHOR                 => 'Lionel Cons <lionel.cons@cern.ch>',
    VERSION                => '1.4',
    ABSTRACT_FROM          => 'lib/Config/Validator.pm',
    LICENSE                => 'perl',
    PL_FILES               => {},
    BUILD_REQUIRES => {
        # optional: Pod::Coverage
        'Test::More'       => 0,
        # optional: Test::Pod
        # optional: Test::Pod::Coverage
    },
    PREREQ_PM => {
        'No::Worries'      => '1.1',
        'Scalar::Util'     => 0,
        'URI::Escape'      => 0,
    },
    dist                   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean                  => { FILES => 'Config-Validator-*' },
);

($emv = $ExtUtils::MakeMaker::VERSION) =~ s/_//;
if ($emv < 6.5503) {
    # missing BUILD_REQUIRES
    foreach $name (keys(%{ $param{BUILD_REQUIRES} })) {
	$param{PREREQ_PM}{$name} = $param{BUILD_REQUIRES}{$name};
    }
    delete($param{BUILD_REQUIRES});
}
if ($emv < 6.31) {
    # missing LICENSE
    delete($param{LICENSE});
}

WriteMakefile(%param);
