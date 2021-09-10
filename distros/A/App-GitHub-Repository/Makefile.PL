use strict;
use warnings;
use ExtUtils::MakeMaker;

my %make;
if ($ExtUtils::MakeMaker::VERSION > 6.64) {
   $make{META_MERGE} = {
    'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/JJ/p5-app-github-repository.git',
                web  => 'https://github.com/JJ/p5-app-github-repository',
            },
        },
    };
}

WriteMakefile(
    NAME                => 'App::GitHub::Repository',
    AUTHOR              => 'JJ Merelo <jjmerelo@gmail.com>',
    VERSION_FROM        => 'lib/App/GitHub/Repository.pm',
    ABSTRACT_FROM       => 'lib/App/GitHub/Repository.pm',
    LICENSE             => 'perl_5',
    PL_FILES            => {},
    PREREQ_PM => {
		  'Test::More' => 0,
		  'Git'        => 0,
		  'File::Slurper' => 0,
		  'JSON'       => 0,
		  'version'    => 0,
		  'Test::Builder::Module' => 0,
		  'Test::Perl::Critic' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-GitHub-Repository-*' },
    %make,
);
