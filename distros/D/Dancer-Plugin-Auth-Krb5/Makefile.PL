use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Auth::Krb5',
    AUTHOR              => q{Hypo Lin <hlin@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/Plugin/Auth/Krb5.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/Auth/Krb5.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Authen::Krb5::Simple' => 0.43,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-Auth-Krb5-*' },
);
