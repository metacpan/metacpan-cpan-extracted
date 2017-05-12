use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME		    => 'CGIS',
    VERSION_FROM	=> 'CGIS.pm',
    PREREQ_PM		=> {
            'CGI::Session' => undef,
    },
    ABSTRACT_FROM   => 'CGIS.pm',
    AUTHOR          => 'Sherzod B. Ruzmetov <sherzodr@cpan.org>'
);

