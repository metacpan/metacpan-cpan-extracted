use strict;
use warnings;

use ExtUtils::Depends;
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

my $pkg = ExtUtils::Depends->new(
    'B::Hooks::OP::Check::LeaveEval',
    'B::Hooks::OP::Check',
);

WriteMakefile(
    NAME               => 'B::Hooks::OP::Check::LeaveEval',
    VERSION_FROM       => 'lib/B/Hooks/OP/Check/LeaveEval.pm',
    ABSTRACT_FROM      => 'lib/B/Hooks/OP/Check/LeaveEval.pm',
    MIN_PERL_VERSION   => '5.10.1',
    LICENSE            => 'perl',
    test               => { TESTS => 't/*.t' },
    eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources   => {
                repository => {
                    type => 'git',
                    url  => 'https://github.com/s-nez/b-hooks-op-check-leaveeval.git',
                    web  => 'https://github.com/s-nez/b-hooks-op-check-leaveeval',
                },
            },
        },
    ) : (),
    $pkg->get_makefile_vars(),
);
