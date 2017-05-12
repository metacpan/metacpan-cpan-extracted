use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME           => 'Compress::LZ4',
    AUTHOR         => 'gray <gray@cpan.org>',
    LICENSE        => 'perl',
    VERSION_FROM   => 'lib/Compress/LZ4.pm',
    ABSTRACT_FROM  => 'lib/Compress/LZ4.pm',
    PREREQ_PM      => {
        Exporter => '5.57',
        XSLoader => 0,
    },
    BUILD_REQUIRES => { 'Test::More' => 0.82, },
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/gray/compress-lz4',
        },
    },

    MYEXTLIB => 'src/lz4$(LIB_EXT)',
    INC      => '-Isrc',

    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean  => { FILES    => 'Compress-LZ4-*' },
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
\$(MYEXTLIB): src/Makefile
\tcd src && \$(MAKE) \$(PASSTHRU)

authortest:
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"
    MAKE_FRAG
}

sub MY::dist_test {
    return shift->MM::dist_test . <<"    MAKE_FRAG";
\tcd \$(DISTVNAME) && \$(MAKE) authortest \$(PASTHRU)
    MAKE_FRAG
}
