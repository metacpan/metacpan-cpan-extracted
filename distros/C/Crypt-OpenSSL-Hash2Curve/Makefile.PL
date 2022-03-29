use 5.008005;
use ExtUtils::MakeMaker;
use Config;

# This is similar to what Crypt::OpenSSL::EC does.
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

$lib =~ s/[\r\n]+/ /g;
$inc =~ s/[\r\n]+/ /g;

WriteMakefile(
    NAME              => 'Crypt::OpenSSL::Hash2Curve',
    VERSION_FROM      => 'Hash2Curve.pm',
    'LICENSE'  => 'mpl_2_0', 
    PREREQ_PM         => { 
        'Crypt::OpenSSL::Bignum' => 0.09,
        'Crypt::OpenSSL::EC' => 1.31,
        'Math::BigInt' => 1.999815,
        'Carp' => 0.01,
        'Test::More' => 0.01,
                          }, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'Hash2Curve.pm', 
       AUTHOR         => 'Pan Lanlan <abbypan@gmail.com>') : ()),
    LIBS              => [ $lib ],
    DEFINE            => '-DPERL5 -DOPENSSL_NO_KRB5',
    INC               => $inc,
    dist => {
        COMPRESS => "bzip2",
        SUFFIX   => ".bz2"
    },
);
