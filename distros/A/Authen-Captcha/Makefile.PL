use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Authen::Captcha',
    'VERSION_FROM'	=> 'Captcha.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	                    'File::Spec'	=> '0.8',
	                    'File::Basename'	=> 0,
	                    'String::Random'	=> 0,
	                    'GD'	=> 0,
	                   },
    ($] >= 5.008 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Captcha.pm', # retrieve abstract from module
       AUTHOR     => 'Seth T. Jackson <sjackson@purifieddata.net>',
       META_MERGE => {
                      'meta-spec' => { version => 2 },
                      resources => {
                                    repository => {
					           type => 'git',
					           url => 'https://github.com/lkundrak/perl-Authen-Captcha.git',
					           web => 'https://github.com/lkundrak/perl-Authen-Captcha',
                                                  },
                                   },
                     }) : ())
);
