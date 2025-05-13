use strict;
use warnings;

use 5.008_000;

use ExtUtils::MakeMaker 6.30;

my %WriteMakefileArgs = (
    "ABSTRACT"       => "Support notifications in your Dancer2 web application",
    "AUTHOR"         => "Samuel Smith <esaym\@cpan.org>",
    "BUILD_REQUIRES" => {},
    "TEST_REQUIRES"  => {
        'Test::More'            => 0,
        'Plack::Test'           => 0,
        'HTTP::Request::Common' => 0,
        'HTTP::Cookies'         => 0,
    },
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => "6.30"
    },
    "DISTNAME"  => "Dancer2-Plugin-FlashNote",
    "EXE_FILES" => [],
    "LICENSE"   => "artistic_2",
    "NAME"      => "Dancer2::Plugin::FlashNote",
    "PREREQ_PM" => {
        "Dancer2"              => "0.0001",
        "Dancer2::Core::Types" => "0.0001",
        "Dancer2::Plugin"      => "0.0001",
    },
    "VERSION_FROM" => "lib/Dancer2/Plugin/FlashNote.pm",
    "test"    => {
        "TESTS" => "t/*.t"
    },
    'META_MERGE' => {
        'resources' => {
            'repository' =>
              'https://github.com/smith153/Dancer2-Plugin-FlashNote',
        },
    },
);

WriteMakefile(%WriteMakefileArgs);

