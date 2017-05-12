use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::ErrorControl',
    'VERSION_FROM'	=> 'ErrorControl.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        HTML::Template::Set => 1.010,
        Class::Date         => 1.1.6,
        Apache::File        => 1.01,
        Apache::Constants   => 1.09,
        Apache::Request     => 1.1,
        MIME::Entity        => 5.404
    }, # e.g., Module::Name => 1.1
);
