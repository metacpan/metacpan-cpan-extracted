use lib inc; use Devel::AssertOS qw(Unix Cygwin);

use ExtUtils::MakeMaker 6.30;

WriteMakefile(
    NAME              => 'Data::Password::passwdqc',
    AUTHOR            => q{Sherwin Daganato <sherwin@daganato.com>},
    VERSION_FROM      => 'lib/Data/Password/passwdqc.pm',
    ABSTRACT_FROM     => 'lib/Data/Password/passwdqc.pm',
    LICENSE           => 'perl',
    BUILD_REQUIRES    => {
        'Test::More'           => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'  => '6.30'
    },
    PREREQ_PM         => {
        'Moose'                => 0,
        'List::MoreUtils'      => 0,
        'namespace::autoclean' => 0,
        'Carp'                 => 0,
    },
    INC               => '-I. -I./src/passwdqc',
    MYEXTLIB          => 'src/libpasswdqc$(LIB_EXT)',
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/sherwind/Data-Password-passwdqc/issues',
            repository  => 'https://github.com/sherwind/Data-Password-passwdqc.git',
        },
    },
);

sub MY::postamble {
    return '
$(MYEXTLIB): src/Makefile
	cd src && $(MAKE) $(PASSTHRU)
';
}

