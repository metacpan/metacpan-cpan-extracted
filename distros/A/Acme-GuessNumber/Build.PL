#! /usr/bin/perl -w
require 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $build = Module::Build->new(
    dist_name       => "Acme-GuessNumber",
    dist_version    => "0.05",
    dist_abstract   => "Automatic number guessing game robot",
    dist_author     => "imacat <imacat\@mail.imacat.idv.tw>",
    license         => "perl",
    sign            => 1,

    build_requires		=> {
        "Module::Signature"	=> 0,
        "Test::Pod"		=> 0,
    },

    meta_merge  => {
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

$build->create_build_script;

__END__
