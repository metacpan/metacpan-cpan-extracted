use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Blog',
    'VERSION_FROM' => 'Blog.pm', # finds $VERSION
    'AUTHOR' => 'Daniel Gardner <daniel@danielgardner.org>',
    'PREREQ_PM' => { 'Date::Manip' => 0,
                     'HTML::Template' => 0,
		     'Apache::Request' => 0,
		     'Apache::Constants' => 0,
		   },
);
