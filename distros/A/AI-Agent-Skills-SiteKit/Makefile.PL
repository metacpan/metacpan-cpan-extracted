use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'AI::Agent::Skills::SiteKit',
    VERSION_FROM => 'lib/AI/Agent/Skills/SiteKit.pm',
    ABSTRACT => 'URL helpers for AI Agent Skills',
    AUTHOR => 'AI Agent Skills <hello@aiagentskills.net>',
    LICENSE => 'mit',
    META_MERGE => {
        resources => {
            homepage => 'https://aiagentskills.net',
            repository => {
                type => 'git',
                url => 'https://github.com/bbwdadfg/aiagentskills-site-kit.git',
                web => 'https://github.com/bbwdadfg/aiagentskills-site-kit',
            },
        },
    },
);
