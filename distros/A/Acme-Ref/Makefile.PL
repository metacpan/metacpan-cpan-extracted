use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::Ref',
    'VERSION_FROM'	=> 'Ref.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?
       (AUTHOR     => 'Raoul Zwart <rlzwart@cpan.org>') : ()),
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
);
