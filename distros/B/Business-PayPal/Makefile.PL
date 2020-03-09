use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Business::PayPal',
    'VERSION_FROM'  => 'lib/Business/PayPal.pm', # finds $VERSION
    'PREREQ_PM'     => {
                           'Net::SSLeay' => 1.14,
                           'Digest::MD5' => 0,
                           'Test::More'  => '1.00',
                       }, # e.g., Module::Name => 1.1
($] >= 5.005 ?    ## Add these new keywords supported since 5.005
       (ABSTRACT_FROM => 'lib/Business/PayPal.pm', # retrieve abstract from module
        AUTHOR     => 'phred <fred@redhotpenguin.com>') : ()),

    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),

    (eval { ExtUtils::MakeMaker->VERSION(6.46) }
      ? (META_MERGE => {
          resources => {
            repository => 'http://github.com/szabgab/Business-PayPal',
          }
        })
      : ()
    ),

);
