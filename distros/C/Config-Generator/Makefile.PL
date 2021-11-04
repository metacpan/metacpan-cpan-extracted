use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%param, $emv);

%param = (
    NAME           => 'Config::Generator',
    AUTHOR         => 'Lionel Cons <lionel.cons@cern.ch>',
    VERSION        => '1.1',
    ABSTRACT       => 'general purpose configuration generator',
    LICENSE        => 'perl',
    EXE_FILES      => [ 'bin/yacg' ],
    PL_FILES       => {},
    BUILD_REQUIRES => {
        # optional: Pod::Coverage
        'Test::More'        => 0,
        # optional: Test::Pod
        # optional: Test::Pod::Coverage
    },
    PREREQ_PM => {
        'Config::General'   => 0,
        'Config::Validator' => '1.2',
        'Digest::MD5'       => 0,
        'FindBin'           => 0,
        'Getopt::Long'      => 0,
        'JSON'              => 0,
        'No::Worries'       => '1.1',
        'POSIX'             => 0,
        'Params::Validate'  => 0,
        'Pod::Usage'        => 0,
        'XML::Parser'       => 0,
    },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean          => { FILES => 'Config-Generator-*' },
);

($emv = $ExtUtils::MakeMaker::VERSION) =~ s/_//;
if ($emv < 6.5503) {
    # missing BUILD_REQUIRES
    foreach my $name (keys(%{ $param{BUILD_REQUIRES} })) {
	$param{PREREQ_PM}{$name} = $param{BUILD_REQUIRES}{$name};
    }
    delete($param{BUILD_REQUIRES});
}
if ($emv < 6.31) {
    # missing LICENSE
    delete($param{LICENSE});
}

WriteMakefile(%param);
