use ExtUtils::MakeMaker;

use Devel::PPPort;

Devel::PPPort::WriteFile();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/FGasper/p5-CBOR-Free.git',
                web => 'https://github.com/FGasper/p5-CBOR-Free',
            },
            bugtracker => {
                web => 'https://github.com/FGasper/p5-CBOR-Free/issues',
            },
        },
    },

    NAME         => 'CBOR::Free',
    AUTHOR       => 'Felipe Gasper (FELIPE)',
    VERSION_FROM => 'lib/CBOR/Free.pm',         # finds \$VERSION
    ABSTRACT_FROM => 'lib/CBOR/Free.pm',
    LICENSE      => 'perl',

    INC => '-I.',

    OBJECT => [
        '$(BASEEXT)$(OBJ_EXT)',
        'cbor_free_boolean.o',
        'cbor_free_encode.o',
        'cbor_free_decode.o',
    ],

    CONFIGURE_REQUIRES => {
        # 'ExtUtils::MakeMaker' => 7.12,
        'Devel::PPPort' => 0,
    },

    # Because of X::Tiny
    MIN_PERL_VERSION => 5.010000,

    PREREQ_PM    => {
        'parent'    => 0,
        'X::Tiny'   => 0,
        'Text::Control' => 0,
        'Types::Serialiser' => 0,
        'XSLoader' => 0.24,

        # Perl 5.10.1 ships 1.82, which mishandles
        # abstract-namespace Linux sockets. (But why did I care?)
        # 'Socket' => 1.87,
    },

    TEST_REQUIRES => {
        'autodie'         => 0,
        'FindBin' => 0,
        'Data::Dumper'    => 0,
        'Test::Exception' => 0,
        'Test::More'      => 1.302133,
        'Test::FailWarnings' => 0,
        'Test::Deep'      => 0,
        'Test::Differences' => 0,
    },

    # SIGN => 1,
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
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
