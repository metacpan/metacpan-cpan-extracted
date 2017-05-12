use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'DBIx::VersionedSubs',
    'VERSION_FROM'  => 'lib/DBIx/VersionedSubs.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Class::Data::Inheritable' => 0,
                        'DBD::SQLite'     => 1.09, # Needed for testing only
                        'Template'        => 0,    # Needed for sample code only
			'HTTP::Server::Simple' => 0, # for the examples
                      }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/DBIx/VersionedSubs.pm', # retrieve abstract from module
       AUTHOR     => 'Max Maischein <corion@cpan.org>') : ()),
);

1;
