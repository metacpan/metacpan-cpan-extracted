use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'Mac::AssistantFrames',
    DISTNAME	=> 'AssistantFrames',
    VERSION_FROM => 'AssistantFrames.pm', # finds $VERSION
    dist	=> { 
        PREOP => 'co -l README && pod2text AssistantFrames.pm >README && ci -u README',
        COMPRESS => 'gzip -9f', 
	SUFFIX => 'gz', 
    },
);
