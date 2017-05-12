use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'Crypt::Skip32::XS',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Crypt/Skip32/XS.pm',
    ABSTRACT_FROM => 'lib/Crypt/Skip32/XS.pm',
    PREREQ_PM     => {
        'Test::More' => 0,
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/crypt-skip32-xs',
        }
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Crypt-Skip32-XS-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

WriteMakefile(%conf);


sub MY::postamble {
    return <<"    MAKE_FRAG";
authortest:
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"
    MAKE_FRAG
}

sub MY::dist_test {
    my $self = shift;
    return $self->MM::dist_test . <<"    MAKE_FRAG";
\tcd \$(DISTVNAME) && \$(MAKE) authortest \$(PASTHRU)
    MAKE_FRAG
}
