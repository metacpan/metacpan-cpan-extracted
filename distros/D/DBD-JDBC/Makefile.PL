use 5.006;
use strict;
use warnings;
use DBI 1.03;
use DBI::DBD;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBD::JDBC',
    AUTHOR           => q{Gennis Emerson <gemerson@vizdom.com>},
    VERSION_FROM     => 'lib/DBD/JDBC.pm',
    ABSTRACT         => 'DBI proxy driver using JDBC',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'DBI'     => '1.48',
        'Convert::BER' => 1.31,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'server' },
);


package MY;
sub postamble { return main::dbd_postamble(@_); }
sub libscan {
    my ($self, $path) = @_;
    ($path =~ m/\~$/) ? undef : $path;
}
sub test {
    my @cp = ("server/dbd_jdbc.jar",
              "server/log4j-api-2.17.1.jar",
              "server/log4j-core-2.17.1.jar",
              "server",
              "t/hsqldb/hsqldb-1.8.0.2.jar",
              "t/hsqldb/log4j-1.2.13.jar",
              "\$(CLASSPATH)");
    my $inherited = shift->SUPER::test(@_);
    if ($^O eq 'MSWin32') {
        my $cp = join ';', @cp; 
        $inherited =~ s/\$\(FULLPERLRUN\)/set CLASSPATH=$cp\n\t\$\(FULLPERLRUN\)/g;
    }
    else {
        my $cp = join ':', @cp; 
        $inherited =~ s/\$\(FULLPERLRUN\)/CLASSPATH=$cp \$\(FULLPERLRUN\)/g;
    }
    return $inherited;
}
