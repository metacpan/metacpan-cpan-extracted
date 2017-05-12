use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.3002;

WriteMakefile(
NAME           => 'App::MetaCPAN::Gtk2::Notify',
    AUTHOR         => q{Pavel Shaydo <zwon@cpan.org>},
    VERSION_FROM   => 'lib/App/MetaCPAN/Gtk2/Notify.pm',
    ABSTRACT_FROM  => 'lib/App/MetaCPAN/Gtk2/Notify.pm',
    LICENSE        => 'perl',
    PL_FILES       => {},
    EXE_FILES      => [ 'bin/metacpan_notify.pl' ],
    PREREQ_PM => {
        'Test::More' => 0.94,
        'JSON'     => 0,
'LWP::UserAgent' => 0,
	'LWP::Protocol::https' => 0,
'Gtk2::Notify' => 0,
	'File::Slurp' => 0,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'App-MetaCPAN-Gtk2-Notify-*' },
    META_MERGE => {
        no_index  => { file => 'README.pod' },
        resources => {
            homepage   => 'https://github.com/trinitum/perl-App-MetaCPAN-Gtk2-Notify',
            bugtracker => 'https://github.com/trinitum/perl-App-MetaCPAN-Gtk2-Notify/issues',
            repository => 'git://github.com/trinitum/perl-App-MetaCPAN-Gtk2-Notify',
            license    => 'http://dev.perl.org/licenses/',
        },
    },
);
