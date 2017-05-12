use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'CGI::Session::Auth',
    'VERSION'	=> '1.07',
    PREREQ_PM   => {
        'CGI' => '0',
        'CGI::Session' => '0',
        'Digest::MD5' => '0',
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Auth.pm', # retrieve abstract from module
       AUTHOR     => 'Jochen Lillich <geewiz@cpan.org>') : ()),
);
