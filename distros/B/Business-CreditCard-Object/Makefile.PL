use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Business::CreditCard::Object',
    'VERSION_FROM'	=> 'lib/Business/CreditCard/Object.pm', 
    'PREREQ_PM'		=> { 
			'Business::CreditCard' => '',
		},
);
