## -*- Perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(
		NAME	  			=> "Class::DBI::Form",
	  VERSION_FROM 	=> "Form.pm",
	 	PREREQ_PM     => {
	 	                   'HTML::Tag' => 0,
											 'Class::DBI::Plugin::Type' => 0,
											 'Tie::IxHash'=> 0,
											 'URI::Escape' => 0
                     },
	      ($] >= 5.005 ?
	       (
		ABSTRACT   => "Convert Class::DBI record in HTML field",
		AUTHOR	   => "Emiliano Bruni <info\@ebruni.it>") : ()),
	      );

# vim: set ts=2:
