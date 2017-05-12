use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;
install_share 'share';

WriteMakefile(
    NAME                => 'Dancer2::Plugin::Auth::Extensible',
    AUTHOR              => q{David Precious <davidp@preshweb.co.uk>},
    VERSION_FROM        => 'lib/Dancer2/Plugin/Auth/Extensible.pm',
    ABSTRACT_FROM       => 'lib/Dancer2/Plugin/Auth/Extensible.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('MIN_PERL_VERSION'=> '5.6.0')
      : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 0,
        "File::ShareDir::Install" => "0.06",
    },
    BUILD_REQUIRES => {
        'DateTime' => 0,
        'File::ShareDir::Install' => '0.06',
        'HTTP::Cookies' => 0,
        'HTTP::Request::Common' => 0,
        'Path::Tiny' => '0.016',
        'Plack::Test' => 0,
        'Test::Deep' => '0.114', # noneof
        'Test::Exception' => 0,
        'Test::MockDateTime' => 0,
        'Test::More' => 0,
        'Test::Warnings' => 0,
    },
    PREREQ_PM => {
        'Carp'              => 0,
        'Dancer2'           => '0.204000',
        'Dancer2::Core::Types' => 0,
        'Dancer2::FileUtils' => 0,
        'Dancer2::Plugin'   => 0,
        'Dancer2::Template::Tiny' => 0,
        'File::Share'       => 0,
        'Module::Runtime'   => 0,
        'Crypt::SaltedHash' => 0,
        'HTTP::BrowserDetect' => 0,
        'List::Util'        => 0,
        'Moo'               => '2.000000',
        'Moo::Role'         => 0,
        'namespace::clean'  => 0,
        'YAML'              => 0, # for config files and tests
        'Scalar::Util'      => 0,
        'Session::Token'    => 0,
        'Try::Tiny'         => 0,
        'Plack'             => '1.0029', # OO-style Plack::Test
        'URI::Escape'       => 0,
    },
    EXE_FILES => [ 'bin/dancer2-generate-crypted-password' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer2-Plugin-Auth-Extensible-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible',
            bugtracker => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible/issues',
            homepage   => 'https://github.com/PerlDancer/Dancer2-Plugin-Auth-Extensible/',
            IRC        => 'irc://irc.perl.org/#dancer',
        },
    },

);
{
package
MY;
use File::ShareDir::Install 'postamble';
}
