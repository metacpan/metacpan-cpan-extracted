use strict;
use warnings;
use ExtUtils::MakeMaker 6.58;
my $from = 'lib/Bash/Completion/Plugins/VimTag.pm';
WriteMakefile(
    ABSTRACT_FROM      => $from,
    AUTHOR             => 'Marcel Gruenauer <marcel@cpan.org>',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.58' },
    LICENSE            => 'perl',
    NAME               => 'Bash::Completion::Plugins::VimTag',
    PREREQ_PM          => {
        'Bash::Completion'     => '0',
        'Path::Iterator::Rule' => '0',
        'parent'               => '0',
    },
    VERSION_FROM => $from,
    test         => { TESTS => 't/*.t' }
);
