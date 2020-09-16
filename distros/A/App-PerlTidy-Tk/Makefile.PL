use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'App::PerlTidy::Tk',
    AUTHOR       => q{Gabor Szabo <szabgab@cpan.org>},
    VERSION_FROM => 'lib/App/PerlTidy/Tk.pm',
    ABSTRACT_FROM => 'lib/App/PerlTidy/Tk.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Browser::Open' => 0,
        'Cpanel::JSON::XS' => 0,
        'File::HomeDir' => 0,
        'Path::Tiny'    => 0,
        'Perl::Tidy'    => 0,
        'Tk'            => 0,
        'Tk::HyperText' => 0,

        'Test::More'          => 0,
        'Test::CPAN::Changes' => 0,
    },
    EXE_FILES => ['bin/perltidy-tk'],
    META_MERGE    => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/szabgab/App-PerlTidy-Tk.git',
                 web  => 'https://github.com/szabgab/App-PerlTidy-Tk.com',
             },
             bugtracker => {web => 'https://github.com/szabgab/App-PerlTidy-Tk/issues'},
             homepage   => 'https://perlmaven.com/tk',
         },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
