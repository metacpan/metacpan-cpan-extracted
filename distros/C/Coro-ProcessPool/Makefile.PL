use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

die "Coro::ProcessPool is not compatible with MSWin32 systems\n".
    "OS unsupported\n" #for cpantesters
    if $^O eq 'MSWin32';

WriteMakefile1(
    NAME                => 'Coro::ProcessPool',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Coro/ProcessPool.pm',
    ABSTRACT            => '',
    LICENSE             => 'BSD License',
    MIN_PERL_VERSION    => '5.006',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jsober/Coro-ProcessPool',
        },
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Coro-ProcessPool-*' },
    PREREQ_PM => {
        'AnyEvent'          => 0,
        'Const::Fast'       => 0,
        'Coro'              => 0,
        'Data::UUID'        => 0,
        'Devel::StackTrace' => 0,
        'Guard'             => 0,
        'Module::Load'      => 0,
        'Moo'               => 0,
        'Sereal'            => 0,
        'Storable'          => '2.05',
        'String::Escape'    => 0,
        'Sub::Override'     => 0,
        'Types::Standard'   => '1.0',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

