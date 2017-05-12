
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Business-BR-Ids',
    VERSION_FROM      => 'lib/Business/BR/Ids.pm', 
    PREREQ_PM         => {
        Scalar::Util    => 1.11, 
        Test::More      => 0, 
    }, 
    ($] >= 5.005 ? (
       ABSTRACT_FROM => 'lib/Business/BR/Ids.pm',
       AUTHOR         => 'A. R. Ferreira <ferreira@cpan.org>'
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
        LICENSE => 'perl', 
    ) :())
);
