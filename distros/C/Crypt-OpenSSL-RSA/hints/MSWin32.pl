use Config;
use Crypt::OpenSSL::Guess 0.11 qw(openssl_lib_paths);
if (my $libs = `pkg-config --libs libssl libcrypto 2>nul`) {
  # strawberry perl has pkg-config
  $self->{LIBS} = [openssl_lib_paths() . " $libs"];
}
else {
  $self->{LIBS} = [openssl_lib_paths() . '-lssleay32 -llibeay32'] if $Config{cc} =~ /cl/; # msvc with ActivePerl
  $self->{LIBS} = [openssl_lib_paths() . '-lssl32 -leay32']       if $Config{gccversion}; # gcc
}
