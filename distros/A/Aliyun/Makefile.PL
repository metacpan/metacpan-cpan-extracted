use 5.024003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Aliyun',
    VERSION_FROM      => 'lib/Aliyun.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'Mojolicious' => 0,
        'Cpanel::JSON::XS' => 0,
        'version' => 0,
        }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Aliyun.pm', # retrieve abstract from module
    AUTHOR            => 'CGI.NET <loveme1314@gmail.com>',
    LICENSE           => 'MIT',
    META_MERGE => {     
        resources => {     repository => 'https://github.com/nsnake/Aliyun',     },     
    },
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
