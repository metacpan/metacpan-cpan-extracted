use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%param, $emv, $name);

%param = (
    NAME                   => 'Authen::Credential',
    AUTHOR                 => 'Lionel Cons <lionel.cons@cern.ch>',
    VERSION                => '1.2',
    ABSTRACT_FROM          => 'lib/Authen/Credential.pm',
    LICENSE                => 'perl',
    PL_FILES               => {},
    BUILD_REQUIRES => {
        # optional: Pod::Coverage
        'Test::More'       => 0,
        # optional: Test::Pod
        # optional: Test::Pod::Coverage
    },
    PREREQ_PM => {
        'MIME::Base64'     => 0,
        'No::Worries'      => '1.1',
        'Params::Validate' => 0,
        'URI::Escape'      => 0,
    },
    dist                   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean                  => { FILES => 'Authen-Credential-*' },
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
