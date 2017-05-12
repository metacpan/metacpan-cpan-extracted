use strict;
use warnings;

use ExtUtils::MakeMaker 6.52;
use Devel::CheckLib;

my $ctz = check_lib(
    lib      => 'c',
    function => 'return (__builtin_ctzll(0x100000000LL) != 32);'
) ? '-DHAVE_BUILTIN_CTZ' : '';

my %conf = (
    NAME               => 'Compress::Snappy',
    AUTHOR             => 'gray <gray@cpan.org>',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/Compress/Snappy.pm',
    ABSTRACT_FROM      => 'lib/Compress/Snappy.pm',
    CONFIGURE_REQUIRES => {
        'Devel::CheckLib'     => 0,
        'ExtUtils::MakeMaker' => 6.52,
    },
    PREREQ_PM          => {
        Exporter => '5.57',
        XSLoader => 0,
    },
    BUILD_REQUIRES => { 'Test::More' => 0.82, },
    META_MERGE     => {
        resources => {
            repository => 'http://github.com/gray/compress-snappy',
        },
    },

    DEFINE => $ctz,

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Compress-Snappy-*' },
);

my $eumm_version =  do {
    no warnings 'numeric';
    eval $ExtUtils::MakeMaker::VERSION;
};
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
