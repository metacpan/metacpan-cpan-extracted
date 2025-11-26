use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AI::Anthropic',
    VERSION_FROM     => 'lib/AI/Anthropic.pm',
    ABSTRACT         => 'Perl interface to Anthropic Claude API',
    AUTHOR           => 'Your Name <your@email.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    
    PREREQ_PM => {
        'HTTP::Tiny'   => '0.070',
        'JSON::PP'     => '2.0',
        'MIME::Base64' => '0',
        'Carp'         => '0',
    },
    
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/yourusername/AI-Anthropic.git',
                web  => 'https://github.com/yourusername/AI-Anthropic',
            },
            bugtracker => {
                web => 'https://github.com/yourusername/AI-Anthropic/issues',
            },
        },
        keywords => [
            'anthropic', 'claude', 'ai', 'llm', 'api', 
            'chatbot', 'gpt', 'language-model',
        ],
    },
);
