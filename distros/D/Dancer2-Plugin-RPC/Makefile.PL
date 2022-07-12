#! perl -w
use strict;
use v5.10.1;

use ExtUtils::MakeMaker '6.55_02';

my %extra_prereq = ();

# Earlier combinations can result in warnings by overload
# this won't undo the warning on perl-5.37.2 at the moment
eval "require Cpanel::JSON::XS";
unless ($@) {
    $extra_prereq{'Cpanel::JSON::XS'}  = '4.29';
}

# I saw problems with this on one of the cpantesters reports
eval "require Cookie::Baker::XS";
unless ($@) {
    $extra_prereq{'Cookie::Baker::XS'} = '0.10';
}

WriteMakefile(
    NAME          => 'Dancer2::Plugin::RPC',
    VERSION_FROM  => 'lib/Dancer2/Plugin/RPC.pm',
    ABSTRACT_FROM => 'lib/Dancer2/Plugin/RPC.pm',
    AUTHOR        => 'Abe Timmerman <abeltje@cpan.org>',
    LICENSE       => 'perl',

    PREREQ_PM => {
        'Dancer2'                          => '0.20',
        'JSON'                             => '2.0',
        'JSON::PP'                         => '4.09',
        'MooX::Params::CompiledValidators' => '0.05',
        'RPC::XML'                         => '0.56',
        'Type::Tiny'                       => '1.01',
        'namespace::autoclean'             => '0.16',
        %extra_prereq,
    },

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.55_02',
    },

    BUILD_REQUIRES => {
        'Test::Fatal'      => '0.01',
        'Test::MockObject' => '1.20',
        'Test::Simple'     => '0.88',    # done_testing()
        'Test::Warnings'   => '0.030',
    },

    MIN_PERL_VERSION => '5.010001',

    META_MERGE => {
        'meta-spec' => {
            version    => 2,
        },
        'resources' => {
            license    => [ 'perl_5'],
            homepage   => "https://github.com/abeltje/Dancer2-Plugin-RPC",
            repository => {
                type   => "git",
                url    => "git://github.com/abeltje/Dancer2-Plugin-RPC.git",
                web    => "https://github.com/abeltje/Dancer2-Plugin-RPC",
            },
#            x_IRC      => "irc://irc.perl.org/#amsterdam.pm",
        },
    },
);
