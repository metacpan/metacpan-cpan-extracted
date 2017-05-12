use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Business::PayPal::IPN',
    'VERSION_FROM'	=> 'IPN.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Crypt::SSLeay'=>undef, 'LWP'=>undef}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'IPN.pm', # retrieve abstract from module
       AUTHOR     => 'Sherzod B. Ruzmetov <sherzodr@cpan.org>') : ()),
);
