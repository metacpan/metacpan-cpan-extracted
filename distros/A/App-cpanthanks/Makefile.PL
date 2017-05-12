use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME                => 'App::cpanthanks',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/App/cpanthanks.pm',
    ABSTRACT            => 'Thank your CPAN authors',
    LICENSE             => 'perl',
    PL_FILES            => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('MIN_PERL_VERSION' => 5.010001)
      : ()),
    PREREQ_PM => {
        'Compiler::Lexer'      => 0,
        'Path::Class::Rule'    => 0,
        'MetaCPAN::Client'     => 0,
        'Term::Encoding'       => 0,
        'Term::ANSIColor'      => 3.0,  # introduces 'bright_*' colors
        'List::Util'           => 0,
        'Try::Tiny'            => 0,
        'Getopt::Long'         => 0,
        'Pod::Usage'           => 0,
        ($^O =~ /Win32/
            ? ( 'Win32::Console::ANSI' => 1.0 )
            : ()
        ),
    },
    META_MERGE      => {
        resources => {
            license     =>      'http://dev.perl.org/licenses/',
            bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-cpanthanks',
            repository  =>      'http://github.com/garu/cpanthanks',
        },
    },
    EXE_FILES           => [ 'cpanthanks' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-cpanthanks-*' },
);
