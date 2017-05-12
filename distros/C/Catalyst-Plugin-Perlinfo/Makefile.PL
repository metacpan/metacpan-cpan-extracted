use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# # the contents of the Makefile that is written.
WriteMakefile(
      NAME              => 'Catalyst::Plugin::Perlinfo',
      VERSION_FROM      => 'lib/Catalyst/Plugin/Perlinfo.pm',
      PREREQ_PM         => {
                        'Catalyst' => 5.70,
                        'HTML::Perlinfo' => 1.69
                            },
      ABSTRACT_FROM     => 'lib/Catalyst/Plugin/Perlinfo.pm', # retrieve abstract from module
      AUTHOR            => 'Mike Accardo <accardo@cpan.org>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
