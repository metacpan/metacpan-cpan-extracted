use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(

    'NAME'	        => 'CGI::Persistent',
    'VERSION_FROM'  => 'lib/CGI/Persistent.pm', # finds $VERSION
    'PREREQ_PM'     => {
                            'Persistence::Object::Simple'   => '0',
                            'File::Basename'                => '0',
                       }

);
