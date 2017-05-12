use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'CGI::CRUD',
    VERSION_FROM      => 'lib/CGI/CRUD.pm', # finds $VERSION
    PREREQ_PM         => { CGI::Enurl => 0, CGI::AutoForm => 0, DBIx::IO => 0, DBI => 0, CGI::FastTemplate => 0, CGI => 0, }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CGI/CRUD.pm', # retrieve abstract from module
       AUTHOR         => 'Reed Sandberg') : ()),
);


unless (eval('require Data::Dumper'))
{
    warn("Optional module Data::Dumper not found so you'll\nhave limited ability to debug with mod_perl_debug.pl\n");
}

