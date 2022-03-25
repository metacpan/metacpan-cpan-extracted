use ExtUtils::MakeMaker;
use Config;

my $lib = '-lcrypto';
my $inc = '';
my $nul = $^O eq 'MSWin32' ? 'nul' : '/dev/null';
if (my $dir = $ENV{OPENSSL_PREFIX}) {
  $lib = "-L$dir/lib -lcrypto -lssl";
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
    'NAME'              => 'Crypt::OpenSSL::EVP::MD',
    'VERSION_FROM'      => 'MD.pm',
    'PREREQ_PM'         => {},
    'ABSTRACT_FROM'     => 'MD.pm', # retrieve abstract from module
    'AUTHOR'            => 'Pan Lanlan <abbypan@gmail.com>',
    'LICENSE'           => 'perl',
    'LIBS'              => [ $lib ],
    'DEFINE'            => '-DPERL5 -DOPENSSL_NO_KRB5',
    # perl-5.8/gcc-3.2 needs -DPERL5, and redhat9 likes -DOPENSSL_NO_KRB5
    'INC'               => $inc,
    'MIN_PERL_VERSION'  => '5.006',
    'META_MERGE'        => {
      resources => {
        repository => 'https://github.com/abbypan/Crypt-OpenSSL-EVP-MD',
      },
    },
    dist => { TARFLAGS => '--owner=0 --group=0 -cvf' },
);
