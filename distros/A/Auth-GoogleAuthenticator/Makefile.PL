use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Auth::GoogleAuthenticator',
    AUTHOR              => q{L<mailto:corion@corion.net>},
    VERSION_FROM        => 'lib/Auth/GoogleAuthenticator.pm',
    ABSTRACT            => 'Authenticate through Google Authenticator',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        # Dancer app prereqs
        # These will be unbundled later
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3097,
        'Dancer::Plugin::FlashMessage' => 0,
        'Template'   => 2, # Because Dancer::Plugin::TemplateToolkit does not require Template

        # Auth::GoogleAuthenticator prereqs
        'Authen::OATH' => 0,
        'Convert::Base32' => 0,
        'Math::Random::MT' => 0, # for generation of good passcodes
        'URI::Escape' => 0, # for url-escaping the user name
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Auth-GoogleAuthenticator-*' },
);
