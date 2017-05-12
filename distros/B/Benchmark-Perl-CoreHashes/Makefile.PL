use 5.017010;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Benchmark::Perl::CoreHashes',
    VERSION_FROM      => 'lib/Benchmark/Perl/CoreHashes.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Benchmark/Perl/CoreHashes.pm',
    AUTHOR            => 'Daniel Dragan <bulkdd@cpan.org>',
    LICENSE           => 'perl',
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
    MIN_PERL_VERSION  => 5.017010,
    BUILD_REQUIRES => {
        'List::Util'    => 0,
        'Test::More'    => 0,
        'Time::HiRes'   => 0
    }
);

package MY;

sub install { #make this uninstallable
    return '';
}