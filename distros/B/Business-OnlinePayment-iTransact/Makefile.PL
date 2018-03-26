use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Business::OnlinePayment::iTransact',
    VERSION_FROM      => 'lib/Business/OnlinePayment/iTransact.pm',
    ABSTRACT_FROM     => 'lib/Business/OnlinePayment/iTransact.pm',
    AUTHOR            => 'Bill Gerrard <bill@gerrard.org>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION => '5.008004',
    PREREQ_PM         => {
      'strict'   => 0,
      'Business::OnlinePayment' => 3,
      'Business::OnlinePayment::HTTPS' => 0,
      'XML::Writer' => 0,
      'XML::Hash::XS' => 0,
      'Digest::HMAC_SHA1' => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/billgerrard/Business-OnlinePayment-iTransact.git',
                web  => 'https://github.com/billgerrard/Business-OnlinePayment-iTransact',
            },
        }})
     : ()
    ),
);
