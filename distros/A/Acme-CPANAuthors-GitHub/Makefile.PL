use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME           => 'Acme::CPANAuthors::GitHub',
    AUTHOR         => 'gray <gray@cpan.org>',
    LICENSE        => 'perl',
    VERSION_FROM   => 'lib/Acme/CPANAuthors/GitHub.pm',
    ABSTRACT_FROM  => 'lib/Acme/CPANAuthors/GitHub.pm',
    PREREQ_PM      => { 'Acme::CPANAuthors' => 0.14, },
    BUILD_REQUIRES => { 'Test::More' => 0.82, },
    META_MERGE     => {
        no_index  => { directory => 'scripts' },
        resources => {
            repository => 'http://github.com/gray/acme-cpanauthors-github',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Acme-CPANAuthors-GitHub-*' },
);

my $eumm_version =  do {
    no warnings 'numeric';
    eval $ExtUtils::MakeMaker::VERSION;
};
delete $conf{META_MERGE} if $eumm_version < 6.46;
$conf{PREREQ_PM} = {
    %{ $conf{PREREQ_PM} || {} }, %{ delete $conf{BUILD_REQUIRES} },
} if ($conf{BUILD_REQUIRES} and $eumm_version < 6.5503);

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
