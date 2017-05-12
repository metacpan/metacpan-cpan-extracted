use strict;
use warnings;
use ExtUtils::MakeMaker;

my @scripts = map { "scripts/$_" } qw(module-setup);

WriteMakefile(
    NAME                => 'App::Module::Setup',
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION_FROM        => 'lib/App/Module/Setup.pm',
    ABSTRACT_FROM       => 'lib/App/Module/Setup.pm',
    PL_FILES            => {},
    EXE_FILES		=> \@scripts,
    PREREQ_PM => {
        'Test::More' => 0.87_01,
    },
    META_MERGE => {
      "meta-spec" => { version => 2 },
      "no_index" => {
        "file" => [
           "lib/App/Module/Setup/Templates/Default.pm",
        ]
      },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Module-Setup-*' },
);
