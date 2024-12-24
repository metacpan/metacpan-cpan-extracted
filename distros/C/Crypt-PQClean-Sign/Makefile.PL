use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Crypt::PQClean::Sign',
    VERSION_FROM => 'lib/Crypt/PQClean/Sign.pm',
    LIBS         => '',
    INC          => '-Ipqclean/common',
    CCFLAGS      => '-o $@',
    OBJECT       => 'PQClean.o ' . join(' ', map { s/c$/o/r }
                        <pqclean/crypto_sign/falcon-512/clean/*.c>,
                        <pqclean/crypto_sign/falcon-1024/clean/*.c>,
                        <pqclean/crypto_sign/ml-dsa-44/clean/*.c>,
                        <pqclean/crypto_sign/ml-dsa-65/clean/*.c>,
                        <pqclean/crypto_sign/ml-dsa-87/clean/*.c>,
                        <pqclean/crypto_sign/sphincs-shake-128f-simple/clean/*.c>,
                        <pqclean/crypto_sign/sphincs-shake-128s-simple/clean/*.c>,
                        <pqclean/crypto_sign/sphincs-shake-192f-simple/clean/*.c>,
                        <pqclean/crypto_sign/sphincs-shake-192s-simple/clean/*.c>,
                        <pqclean/crypto_sign/sphincs-shake-256f-simple/clean/*.c>,
                        <pqclean/crypto_sign/sphincs-shake-256s-simple/clean/*.c>,
                        <pqclean/common/*.c>,
                    ),
    clean        => { FILES => 'Crypt-PQClean-Sign-*' },
);
