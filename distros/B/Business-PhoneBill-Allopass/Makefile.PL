use 5.005;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Business::PhoneBill::Allopass',
    'VERSION_FROM'	=> 'Allopass.pm',
    'LICENSE'           =>  'GPL',
    'PREREQ_PM'		=> {
				HTTP::Request::Common => 1.0,
				LWP::UserAgent	      => 1.0,
			},
    ABSTRACT_FROM => 'Allopass.pm',
    AUTHOR        => 'Bernard Nauwelaerts <bpn#it-development%be>'
);