use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";

WriteMakefile(
    NAME              => 'BlankOnDev',
    VERSION_FROM      => 'lib/BlankOnDev.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    "ABSTRACT" => "BlankOnDev - Development tools for BlankOn GNU/Linux.",
    "AUTHOR" => "Achmad Yusri Afandi <yusrideb\@cpan.org>",
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => 0,
        "File::ShareDir::Install" => "0.06"
    },
    "DISTNAME" => "BlankOnDev",
    "EXE_FILES" => [
        "script/perlmake",
        "script/boi_mig.sh",
        "script/boidev"
    ],
    "LICENSE" => "perl",
    "MIN_PERL_VERSION" => "5.01205",
    "NAME" => "BlankOnDev",
    "PREREQ_PM" => {
        "Crypt::Blowfish" => 0,
        "Digest::MD5" => 0,
        "MIME::Base64" => 0,
        "MIME::Base64::Perl" => 0,
        "JSON" => 0,
        "GnuPG" => 0,
        "Hash::MultiValue" => 0,
        "Term::ReadKey" => 0,
        "LWP::UserAgent" => 0,
        "DateTime" => 0,
        "Text::SimpleTable::AutoWidth" => 0,
        "Capture::Tiny" => 0,
        "Capture::Tiny::Extended" => 0,
        "UNIVERSAL::ref" => 0,
        "IPC::Run" => 0,
        "Net::GitHub" => 0,
        "parent" => 0
    },
    "TEST_REQUIRES" => {
        "Test::More" => "0.88",
        "Test::Requires" => 0
    },
    "VERSION_FROM" => 'lib/BlankOnDev/Version.pm',
);

{
    package
    MY;
    use File::ShareDir::Install qw(postamble);
}