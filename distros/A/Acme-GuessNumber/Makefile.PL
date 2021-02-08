#! /usr/bin/perl -w
require 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME        => "Acme::GuessNumber",
    VERSION     => "0.05",
    ABSTRACT    => "Automatic number guessing game robot",
    AUTHOR      => "imacat <imacat\@mail.imacat.idv.tw>",
    PREREQ_PM   => { },
    PL_FILES    => { },
    LICENSE     => "perl",
    SIGN        => 1,

    dist        => {
        COMPRESS    => "gzip -9",
        SUFFIX      => ".gz",
    },

    META_MERGE  => {
        "meta-spec" => { version => 2 },
        resources   => {
            homepage    => "https://metacpan.org/release/Acme-GuessNumber",
            repository  => {
                type    => "git",
                url     => "git://github.com/imacat/Acme-GuessNumber.git",
                web     => "https://github.com/imacat/Acme-GuessNumber",
            },
            bugtracker  => {
                "web"   => "https://github.com/imacat/Acme-GuessNumber/issues"
            }
        },
    },
);

__END__
