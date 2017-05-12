use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my $lib = '-lcrypto';
my $inc = '';
my $nul = $^O eq 'MSWin32' ? 'nul' : '/dev/null';

if (my $dir = $ENV{OPENSSL_PREFIX}) {
  $lib = "-L$dir/lib -lcrypto";
  $inc = "-I$dir/include";
}
elsif ($ENV{OPENSSL_LIB}) {
  $lib = $ENV{OPENSSL_LIB};
  $inc = $ENV{OPENSSL_INCLUDE};
}
elsif (`pkg-config --modversion libcrypto 2>$nul`) {
  $lib = `pkg-config --libs libcrypto 2> $nul`;
  $inc = `pkg-config --cflags libcrypto 2> $nul`;
}
elsif ($^O eq 'MSWin32') {
  $lib = '-llibeay32' if $Config{cc} =~ /cl/;
  $lib = '-leay32'    if $Config{cc} =~ /gcc/;
}

WriteMakefile(
    'NAME'              => 'Crypt::OpenSSL::DSA',
    'VERSION_FROM'      => 'lib/Crypt/OpenSSL/DSA.pm', # finds $VERSION
    'LICENSE'           => 'perl_5',
    'MIN_PERL_VERSION'  => '5.006',
    'PREREQ_PM'         => {}, # e.g., Module::Name => 1.1
    'AUTHOR'            => 'T.J. Mather',
    'LIBS'              => [ $lib ],
    'INC'               => $inc,
    'DEFINE'            => '-DPERL5',   # perl-5.8/gcc-3.2 needs this
    'META_MERGE'        => {
      resources => {
        repository => 'https://github.com/kmx/perl-Crypt-OpenSSL-DSA',
      },
    },
    dist => { TARFLAGS => '--owner=0 --group=0 -cvf' },
);
