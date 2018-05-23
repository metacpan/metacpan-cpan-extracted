use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME               => 'Bing::ContentAPI',
    VERSION_FROM       => 'lib/Bing/ContentAPI.pm',
    ABSTRACT_FROM      => 'lib/Bing/ContentAPI.pm',
    AUTHOR             => 'Bill Gerrard <bill@gerrard.org>',
    LICENSE            => 'Perl_5',
    MIN_PERL_VERSION   => '5.008004',
    PREREQ_PM => {
      'strict'         => 0,
      'warnings'       => 0,
      'Carp'           => 0,
      'JSON'           => 0,
      'REST::Client'   => 0,
      'HTML::Entities' => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/billgerrard/bing-content-api.git',
                web  => 'https://github.com/billgerrard/bing-content-api',
            },
        }})
     : ()
    ),
);
