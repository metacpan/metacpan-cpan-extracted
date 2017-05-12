
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Compress::unLZMA',
    VERSION_FROM      => 'lib/Compress/unLZMA.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ? (
         ABSTRACT_FROM  => 'lib/Compress/unLZMA.pm',
         AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>'
    ) : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I. -Ilzma_sdk/Source',
    ($EUMM_VERSION > 6.4501 ? (
        META_MERGE => {
            resources => {
                repository => 'http://github.com/aferreira/cpan-Compress-unLZMA',
            }
        },
    ) : ()),
);
