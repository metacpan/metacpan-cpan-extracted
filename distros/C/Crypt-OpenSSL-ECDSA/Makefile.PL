use 5.008005;
use ExtUtils::MakeMaker;

# You might need to set this if your openssl headers and libs anre in an unusual place:
my $openssl_prefix = $ENV{OPENSSL_PREFIX} || '/usr';

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Crypt::OpenSSL::ECDSA',
    VERSION_FROM      => 'lib/Crypt/OpenSSL/ECDSA.pm', # finds $VERSION
    PREREQ_PM         => {'Crypt::OpenSSL::EC' => 0.05,
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/OpenSSL/ECDSA.pm', # retrieve abstract from module
       AUTHOR         => 'Mike McCauley <mikem@airspayce.com>') : ()),
    LIBS              => ["-L$openssl_prefix/lib -lcrypto"], 
    DEFINE            => '-DPERL5 -DOPENSSL_NO_KRB5', 
    INC               => "-I. -I$openssl_prefix/include",
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(ECDSA_F_ECDSA_CHECK ECDSA_F_ECDSA_DATA_NEW_METHOD
		 ECDSA_F_ECDSA_DO_SIGN ECDSA_F_ECDSA_DO_VERIFY
		 ECDSA_F_ECDSA_SIGN_SETUP ECDSA_R_BAD_SIGNATURE
		 ECDSA_R_DATA_TOO_LARGE_FOR_KEY_SIZE ECDSA_R_ERR_EC_LIB
		 ECDSA_R_MISSING_PARAMETERS ECDSA_R_NEED_NEW_SETUP_VALUES
		 ECDSA_R_NON_FIPS_METHOD
		 ECDSA_R_RANDOM_NUMBER_GENERATION_FAILED
		 ECDSA_R_SIGNATURE_MALLOC_FAILED));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Crypt::OpenSSL::ECDSA',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
