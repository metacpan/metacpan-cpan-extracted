use Config;
use Crypt::OpenSSL::Guess qw(openssl_lib_paths openssl_inc_paths);

my %args = (
  LIBS => [openssl_lib_paths().' -lssl -lcrypto'],
  INC => openssl_inc_paths(),
);

my $cc_option_flags = " -O2 -g";
my $cc_defines      = '';

if ($Config::Config{cc} =~ /gcc/i) {
  $cc_option_flags .= $ENV{AUTHOR_TESTING} ? ' -Wall -Werror' : ' -Wall';
} else {
  $cc_option_flags .= '';
}

if ($Config{gccversion} =~ /llvm/i) {
  $cc_option_flags .= ' -Wall -Wno-deprecated-declarations';

  if ($Config{gccversion} =~ /llvm 12/i) {
    $cc_option_flags .= ' -Wno-compound-token-split-by-macro';
  }

  if ($Config{gccversion} =~ /llvm 13/i) {
    $cc_option_flags .= ' -Wno-compound-token-split-by-macro';
  }

  if ($Config{gccversion} =~ /llvm 14/i) {
    $cc_option_flags .= ' -Wno-compound-token-split-by-macro';
  }

  if ($Config{perl_version} <= 20) {
    $cc_option_flags .= ' -Wno-error=pointer-bool-conversion';
  }
}

if ($Config{myuname} =~ /sunos|solaris/i) {
  $args{OPTIMIZE} = $cc_option_flags;
} elsif ($Config{myuname} =~ /strawberry-{0,1}perl/i) {
  if ($Config{PERL_VERSION} <= 24) {
    $args{LIBS} = [openssl_lib_paths() . ' -leay32'];
  }
  $cc_defines .= ' -DOPENSSL_NO_SCRYPT';
  $args{DEFINE} = $cc_defines;
} elsif ($Config{myuname} =~ /darwin/ ) {
  $args{LDDLFLAGS} = openssl_lib_paths() . ' ' . $Config{lddlflags};
} else {
  $args{LDDLFLAGS} = openssl_lib_paths() . ' ' . $Config{lddlflags};
  $args{OPTIMIZE} = $cc_option_flags;
}
