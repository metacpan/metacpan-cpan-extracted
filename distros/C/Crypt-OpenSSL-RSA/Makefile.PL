use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $KERBEROS_INCLUDE = "/usr/kerberos/include";

my $include = -d $KERBEROS_INCLUDE ? "-I${KERBEROS_INCLUDE}" : "";

WriteMakefile(
    'NAME'	=> 'Crypt::OpenSSL::RSA',
    'DISTNAME' => 'Crypt-OpenSSL-RSA',
     AUTHOR  => 'Ian Robertson <iroberts@cpan.org>',
    'VERSION_FROM' => 'RSA.pm', # finds $VERSION
    'ABSTRACT_FROM' => 'RSA.pm',
    'PL_FILES' => {},
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'        => 'perl', ) : ()),
    'PREREQ_PM' => {
        'Crypt::OpenSSL::Random' => 0,
        'Test' => 0,
    },
    'OBJECT' => 'RSA.o',
    'LIBS'    => ($^O eq 'MSWin32') ? ['-lssl32 -leay32'] : ['-lssl -lcrypto'],
    'DEFINE'	=> '-DPERL5 -DOPENSSL_NO_KRB5',
    # perl-5.8/gcc-3.2 needs -DPERL5, and redhat9 likes -DOPENSSL_NO_KRB5
    'INC'	=> $include,     # e.g., '-I/usr/include/other'

    'dist'  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    'clean' => { FILES => 'Crypt-OpenSSL-RSA-*' },
    'META_MERGE' => {
        recommends => {
            'Crypt::OpenSSL::Bignum' => 0,
        },
        build_requires => {
            'Test' => 0,  # For testing
        },
        resources => {
            'license' => 'http://dev.perl.org/licenses/',
            'homepage' => 'https://metacpan.org/release/Crypt-OpenSSL-RSA',
#            bugtracker => 'http://code.google.com/p/Crypt-OpenSSL-RSA/issues/list',
            'repository' => 'http://github.com/monken/Crypt-OpenSSL-RSA',
#            MailingList => 'http://groups.google.com/group/Crypt-OpenSSL-RSA',
        }
    }
);

#Nice = Crypt::OpenSSL::Bignum
