use ExtUtils::MakeMaker;
use Config;

my %CFG = (
    'NAME'          => 'Crypt::Passwd::XS',
    'AUTHOR'        => 'cPanel <cpanel@cpan.org>',
    'VERSION_FROM'  => 'lib/Crypt/Passwd/XS.pm',
    'ABSTRACT_FROM' => 'lib/Crypt/Passwd/XS.pm',
    'PL_FILES'      => {},
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    'PREREQ_PM' => {
        'Test::More' => 0,    # For testing
    },
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    'clean'       => { FILES    => 'Crypt-Passwd-XS-* *.o' },
    'INSTALLDIRS' => 'site',
    'OBJECT'      => "sha256crypt.o sha512crypt.o des.o md5.o crypt_to64.o md5crypt.o XS.o",
    'META_MERGE'  => {
        build_requires => {
            'Test::More' => 0,    # For testing
        },
        resources => { license => 'http://dev.perl.org/licenses/', },
    }
);

if ($Config{"byteorder"} =~ /^1234/) {
    $CFG{'DEFINE'} .= ' -DARCH_IS_BIG_ENDIAN=0';
}

if ($^O =~ /^MSWin/i) {
    $CFG{'DEFINE'} .= ' -DWINDOWS';
}

WriteMakefile(%CFG);
