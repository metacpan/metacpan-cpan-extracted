use v5.16;
use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share module => 'App::PFT', 'share';

WriteMakefile1(
    NAME             => 'App::PFT',
    AUTHOR           => q{Giovanni Simoni (dacav at openmailbox)},
    VERSION_FROM     => 'lib/App/PFT.pm',
    ABSTRACT         => 'Hacker friendly static blog generator',
    LICENSE          => 'GNU GPL v3',
    PL_FILES         => {},
    EXE_FILES        => [grep { -x } glob 'bin/*'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'       => 0,
        'File::ShareDir::Install'   => 0,
    },
    TEST_REQUIRES => {
        'Test::More'                => 0,
        'File::Temp'                => 0,
        'Cwd'                       => 0,
        'IPC::Run'                  => 0,
        'PFT'                       => '1.2.1',
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'Cwd'                   => 0,
        'Digest::MD5'           => 0,
        'Encode'                => 0,
        'Encode::Locale'        => 0,
        'Exporter'              => 0,
        'File::Basename'        => 0,
        'File::Copy'            => 0,
        'File::Copy::Recursive' => 0,
        'File::Path'            => 0,
        'File::ShareDir'        => 0,
        'File::Spec'            => 0,
        'File::Spec::Functions' => 0,
        'FindBin'               => 0,
        'Getopt::Long'          => 0,
        'HTML::Escape'          => 0,
        'LWP::Simple'           => 0,
        'Pod::Find'             => 0,
        'Pod::Usage'            => 0,
        'Template::Alloy'       => 0,
        'URI'                   => 0,

        'PFT'                   => v1.2.1,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-PFT-*' },
);

sub WriteMakefile1 {
    # Compatibility code for old versions of EU::MM.
    # Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
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

package MY;
use File::ShareDir::Install qw/postamble/;
