use Config;
use File::Spec;
use Crypt::OpenSSL::Guess qw(openssl_version openssl_inc_paths openssl_lib_paths);

my %args;

my ($major, $minor, $patch) = openssl_version();
print "Installed OpenSSL: $major.$minor.$patch\n";

$args{INC} =  openssl_inc_paths();
$args{LIBS} = [openssl_lib_paths() . ' -lssl -lcrypto'];

my $cc_option_flags;

if ($Config::Config{cc} =~ /gcc/i) {
  $cc_option_flags .= $ENV{AUTHOR_TESTING} ? ' -Wall -Werror' : ' -Wall';
} else {
  $cc_option_flags .= '';
}

if ($Config{gccversion} =~ /llvm/i) {
  if ( $^O eq 'darwin' && (
    $Config{gccversion} =~ /LLVM 1[2-9].\d.[5-9]/ ||
    $Config{gccversion} =~ /LLVM 1[3-9]/ ))
  {
    $cc_option_flags .= ' -Wno-deprecated-declarations -Wno-compound-token-split-by-macro';
  } else {
    $cc_option_flags .= ' -Wno-deprecated-declarations';
  }

  if ($Config{gccversion} =~ /llvm 13/i) {
      $cc_option_flags .= ' -Wno-compound-token-split-by-macro';
  }

  if ($Config{PERL_VERSION} <= 20) {
    $cc_option_flags .= ' -Wno-error=pointer-bool-conversion';
  }
}

if ($Config{myuname} =~ /sunos|solaris/i) {
  $args{OPTIMIZE} = $cc_option_flags;
} else {
  $args{OPTIMIZE} = $cc_option_flags;
}
