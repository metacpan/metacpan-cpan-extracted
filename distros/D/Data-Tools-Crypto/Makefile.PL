use ExtUtils::MakeMaker;

WriteMakefile(

  NAME            => 'Data::Tools::Crypto',
  VERSION_FROM    => 'lib/Data/Tools/Crypto.pm',
  LICENSE         => 'gpl_2',

  ABSTRACT        => 'authenticated symmetric and hybrid RSA encryption and signatures, one common API',
  AUTHOR          => 'Vladi Belperchinov-Shabanski "Cade" <cade@cpan.org>',

  PREREQ_PM       => {

    # str_hex() and str_unhex() for the hex encoding of the API
    'Data::Tools'                      => 0,

    # all Crypt:: modules come from CryptX, Crypt::AuthEnc::ChaCha20Poly1305
    # first appeared in 0.048
    'CryptX'                           => '0.048',

    'Encode'                           => 0,
    'Exception::Sink'                  => 0,

    # 4.0 enables allow_nonref by default, so freeze() can carry plain scalars
    'JSON'                             => '4.0',

    # encode_base64url() and decode_base64url() first appeared in 3.11
    'MIME::Base64'                     => '3.11',

    },

  # the test files are .pl, MakeMaker globs t/*.t by default
  test            => { TESTS => 't/*.pl' },

  META_MERGE      => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/cade-vs/perl-data-tools-crypto.git',
        web  => 'https://github.com/cade-vs/perl-data-tools-crypto',
      },
    },
  },
);
