use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Date::Holidays::NZ',
    'VERSION_FROM' => 'NZ.pm', # finds $VERSION
	      PREREQ_PM => { Set::Object => 1.09,
			     Date::Manip => 0 },
   ($] ge '5.005')
    ? (
     'AUTHOR' => 'Sam Vilain (samv@cpan.org)',
     'ABSTRACT' => 'Determine New Zealand public holidays'
    )
    : (),
);
