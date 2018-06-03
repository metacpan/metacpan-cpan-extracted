use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %params = (
    NAME => "App::Cpanx",
    VERSION_FROM => "lib/App/Cpanx.pm",
    ABSTRACT => "A CPAN downloader script",
    AUTHOR => "Jacob Gelbman <gelbman\@gmail.com>",
    EXE_FILES => ["bin/cpanx"],
    clean => {FILES => "App-Cpanx-*.tar.gz *.bak"},
);

my @requires = (
    "strict" => 0,
    "warnings" => 0,
);

my @test_requires = (
    "Test::More" => 0.88,
);

if ($mm_ver < 6.64) {
    $params{PREREQ_PM} = {@requires, @test_requires};
}
else {
    $params{PREREQ_PM} = {@requires};
    $params{TEST_REQUIRES} = {@test_requires};
}

if ($mm_ver >= 6.31) {
    $params{LICENSE} = "perl";
}

if ($mm_ver >= 6.48) {
    $params{MIN_PERL_VERSION} = 5.006;
}

if ($mm_ver > 6.45) {
    $params{META_MERGE} = {
        "meta-spec" => {version => 2},
        resources => {
            repository => {
                type => "git",
                web => "https://github.com/zorgnax/cpanx",
                url => "https://github.com/zorgnax/cpanx.git",
            }
        }
    };
}

WriteMakefile(%params);

