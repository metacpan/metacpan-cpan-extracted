    use strict;
    use warnings;
     
    use 5.008;
     
    use ExtUtils::MakeMaker;
    WriteMakefile
    (
    NAME => 'Dancer::Plugin::PaypalExpressRoutes',
    AUTHOR => q{Lyn St George <lyn@zolotek.net>},
    VERSION_FROM => 'lib/Dancer/Plugin/PaypalExpressRoutes.pm',
	ABSTRACT => 'Dancer wrapper for Business::PayPal::API::ExpressCheckout',
     PREREQ_PM => {
		'Business::PayPal::API::ExpressCheckout' => '0.14',
		'Dancer::Plugin::Database' => '2.08',
		'Dancer' => '1.3098',
		},
    );
    