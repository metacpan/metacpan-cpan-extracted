use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Business::OnlinePayment::CardFortress',
    AUTHOR              => q{Ivan Kohler <ivan-cardfortress@420.am>},
    VERSION_FROM        => 'lib/Business/OnlinePayment/CardFortress.pm',
    ABSTRACT_FROM       => 'lib/Business/OnlinePayment/CardFortress.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Slurp' => 0,
        'Crypt::OpenSSL::RSA' => 0,
        'Business::OnlinePayment' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Business-OnlinePayment-CardFortress-*' },
);
