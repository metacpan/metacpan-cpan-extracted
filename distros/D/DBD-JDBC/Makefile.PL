use DBI 1.03;
use DBI::DBD;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
        'NAME'  => 'DBD::JDBC',
        'VERSION_FROM' => 'JDBC.pm',
        'NO_META' => 1,
        'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz', },
        'AUTHOR'    => 'Gennis Emerson <gemerson@vizdom.com>',
        'ABSTRACT'  => 'DBI proxy driver using JDBC',
        'PREREQ_PM' => {
           'DBI'     => '1.48',
           'Convert::BER' => 1.31, }, 
); 


package MY;
sub postamble { return main::dbd_postamble(@_); }
sub libscan {
    my ($self, $path) = @_;
    ($path =~ m/\~$/) ? undef : $path;
}
sub test {
    my @cp = ("dbd_jdbc.jar", 
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

