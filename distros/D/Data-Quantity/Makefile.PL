use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Data::Quantity',
    'VERSION_FROM'	=> 'Quantity.pm', 
    'PREREQ_PM'		=> {
	'Class::MakeMethods' => 1.000,
	# These next two come together in the Time-modules distribution
	'Time::JulianDay' => 1,	'Time::ParseDate' => 1,
    }, 
    ($] >= 5.005 ? (
      ABSTRACT_FROM => 'Quantity.pm', 
      AUTHOR     => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);
sub MY::postamble { q{

docs : README CHANGES TODO

README: Quantity/ReadMe.pod
	pod2text Quantity/ReadMe.pod > README

CHANGES: Quantity/Changes.pod
	pod2text Quantity/Changes.pod > CHANGES

TODO: Quantity/ToDo.pod
	pod2text Quantity/ToDo.pod > TODO

cleanmanifest:
	rm MANIFEST ; touch MANIFEST; make manifest

}; }
