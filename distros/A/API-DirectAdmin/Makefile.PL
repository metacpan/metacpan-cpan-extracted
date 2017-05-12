use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'API::DirectAdmin',
    VERSION_FROM      => 'lib/API/DirectAdmin.pm',
    PREREQ_PM         => {
        'Modern::Perl'   => '0',
        'Data::Dumper'   => '0',
        'LWP::UserAgent' => '0',
		'HTTP::Request'  => '0',
		'URI'   		 => '0',
		'Carp'   		 => '0',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/API/DirectAdmin.pm',
       AUTHOR         => 'Andrey "Chips" Kuzmin <chipsoid@cpan.org>') : ()),
);
