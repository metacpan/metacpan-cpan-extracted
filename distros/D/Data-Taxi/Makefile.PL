use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'            => "Data::Taxi",
	'VERSION_FROM'    => "Taxi.pm", # finds $VERSION
	'PREREQ_PM'       => {
		'Debug::ShowStuff' => 1.1,
	}, # e.g., Module::Name => 1.1
	
	# Add these new keywords supported since 5.005
	(
		$] >= 5.005 ?
			(
				ABSTRACT_FROM  => "Taxi.pm", # retrieve abstract from module
				AUTHOR         => "Miko O'Sullivan <miko\@idocs.com>"
			) :
			
			()
	),
);
