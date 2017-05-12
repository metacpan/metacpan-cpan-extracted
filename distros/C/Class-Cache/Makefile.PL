

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Class::Cache',
    VERSION_FROM => 'lib/Class/Cache.pm', # finds \$VERSION
    AUTHOR       => 'Terrence Brannon (metaperl@gmail.com)',
    ABSTRACT     => 'Caching, Refilling Factory',
    PREREQ_PM    => {
      'Test::Simple' => 0.44,
      'Class::Prototyped' => 1.10,
      'Params::Validate' => 0.78
     },
);
