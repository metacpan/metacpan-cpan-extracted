use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::AutoLogin',
    'VERSION_FROM'	=> 'AutoLogin.pm', # finds $VERSION
    'PREREQ_PM'		=> {Apache::Constants => 1.09,
                            Crypt::Rijndael => 0.04,
                            MIME::Base64 => 2.12,
                            Digest::MD5 => 2.13,
                            Apache::Cookie => 0.01,
                            Apache::Request => 0.33,
                            Apache::Log => 1.01}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'AutoLogin.pm', # retrieve abstract from module
       AUTHOR     => 'Marcel M. Weber <mmweber@ncpro.com>') : ()),
);
