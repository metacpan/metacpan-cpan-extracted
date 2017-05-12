use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Type',
    'VERSION_FROM'	=> 'Type.pm', # finds $VERSION
    'PREREQ_PM'		=>
    {


	Class::Maker => '0.05.10',

	Error => '0.15',

	IO::Extended => '0.05',

	Tie::ListKeyedHash => '0.41',

	Iter => '0',


    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Type.pm', # retrieve abstract from module
       AUTHOR     => 'murat.uenalan@cpan.org') : ()),
);
