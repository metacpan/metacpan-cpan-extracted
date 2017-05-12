use 5.008;
use ExtUtils::MakeMaker;
use utf8;

WriteMakefile(
    NAME              => 'Business::OnlinePayment::InternetSecure',
    AUTHOR            => ['Frédéric Brière <fbriere@fbriere.net>',
                          'Slobodan Mišković <slobodan.miskovic@taskforce-1.com>'],
    VERSION_FROM      => 'InternetSecure.pm',
    ABSTRACT_FROM     => 'InternetSecure.pm',
    PREREQ_PM         => {
      'Business::OnlinePayment'	=> 2,
      'Net::SSLeay'   => 0,
      'XML::Simple'   => 0,
    },
);
