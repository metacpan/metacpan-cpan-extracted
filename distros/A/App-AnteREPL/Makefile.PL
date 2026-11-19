use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;

my %prereqs = map { $_ => 0 } qw(
    Data::Dumper Devel::Peek Encode File::Basename File::Spec File::Temp
    POSIX Text::Balanced Text::ParseWords Time::HiRes strict warnings feature
);
$prereqs{'Term::ReadKey'} = 0 if $^O eq 'MSWin32';

WriteMakefile(
    NAME             => 'App::AnteREPL',
    VERSION_FROM     => 'lib/App/AnteREPL.pm',
    ABSTRACT_FROM    => 'lib/App/AnteREPL.pm',
    AUTHOR           => 'Brett Estrade',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
    PREREQ_PM        => \%prereqs,
    TEST_REQUIRES    => { map { $_ => 0 } qw(Test::More Cwd FindBin IPC::Open3 Symbol) },
    EXE_FILES        => ['script/anterepl'],
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'https://github.com/oodler577/p5-App-AnteREPL/wiki',
            repository => {
                type => 'git',
                url => 'https://github.com/oodler577/p5-App-AnteREPL.git',
                web => 'https://github.com/oodler577/p5-App-AnteREPL',
            },
            bugtracker => { web => 'https://github.com/oodler577/p5-App-AnteREPL/issues' },
        },
        prereqs => { runtime => { recommends => { 'Term::ReadKey' => 0 } } },
        no_index => {
            directory => [qw(t tools examples)],
            package => [qw(App::AnteREPL::Screen App::AnteREPL::ScreenInput
                App::AnteREPL::ScreenOutput App::AnteREPL::Evaluator)],
            namespace => ['App::AnteREPL::Workspace'],
        },
    },
);
