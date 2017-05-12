use 5.008001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Crypt::SSSS',
    AUTHOR        => 'Sergey Zasenko <UNDEF@cpan.org>',
    LICENSE       => 'perl',
    ABSTRACT_FROM => 'lib/Crypt/SSSS.pm',
    VERSION_FROM  => 'lib/Crypt/SSSS.pm',

    BUILD_REQUIRES => {'Test::More' => '0.88'},
    PREREQ_PM      => {},
    clean          => {FILES        => 'Crypt-SSSS-*'},
    META_MERGE =>
      {resources => {repository => 'http://github.com/und3f/crypt-ssss',}}
);

sub MY::postamble {
    my $self = shift;
    return <<"END"
readme:
\t/usr/bin/env pod2text $self->{ABSTRACT_FROM} > README
END
}
