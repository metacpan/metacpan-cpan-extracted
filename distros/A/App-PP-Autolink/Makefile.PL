use strict;
use warnings;
use 5.014;
use ExtUtils::MakeMaker;

my @exe_copy;
if ($^O ne 'MSWin32') {
    #  Make a copy of the scipt without the .pl extension.
    #  Clunky as it is not considered by "make clean".
    use File::Copy;
    my $success = eval {copy 'bin/pp_autolink.pl', 'bin/pp_autolink'; 1};
    warn $@ if $@;
    if ($success) {
        @exe_copy = ('bin/pp_autolink');
    }
}

my %WriteMakefileArgs = (
    "ABSTRACT" => "Pack PAR executables, finding dynamic libs automatically",
    "AUTHOR"   => 'Shawn Laffan <shawnlaffan@gmail.com>',
    "NAME"     => "App::PP::Autolink",
    "VERSION_FROM" => "lib/App/PP/Autolink.pm",
    "CONFIGURE_REQUIRES" => {
        "File::Copy" => 0,
    },
    "BUILD_REQUIRES" => {
    },
    "TEST_REQUIRES" => {
        "Test::More" => 0,
        "File::Which" => 0,
    },
    "PREREQ_PM" => {
        'Capture::Tiny'    => '0.48',
        'File::Find::Rule' => 0,
        'File::Which'      => 0,
        'Getopt::ArgvFile' => 0,
        'Module::ScanDeps' => '1.27',
        'PAR::Packer'      => '1.049',
        'Path::Tiny'       => '0.108',
        'rlib'             => '0.02',
        'List::Util'       => '1.45',
        'Env'              => 0,
    },
    EXE_FILES		=> [
        'bin/pp_autolink.pl',
        @exe_copy,
    ],
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shawnlaffan/perl-pp-autolink',
            },
            bugtracker => {
                web => 'https://github.com/shawnlaffan/perl-pp-autolink/issues/',
            },
        },
    },
    "DISTNAME" => "App-PP-Autolink",
    "LICENSE"  => "perl_5",
);


WriteMakefile(%WriteMakefileArgs);

