use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'       => 'Stephen Olander-Waters <stephenw@stedwards.edu>',
    'LICENSE'      => 'perl',
    'NAME'         => 'Apache2::AuthTicketLDAP',
    'ABSTRACT_FROM' => 'AuthTicketLDAP.pm',
    'VERSION_FROM' => 'AuthTicketLDAP.pm',
    'PREREQ_PM'    => {
        'Apache::AuthTicket'    => '0.93',
        'CHI'                   => '0.55', 
	'Cache::FastMmap'       => '1.40',
	'Digest::SHA'           => '0',
	'Net::LDAP'             => '0.46',
	}
);
