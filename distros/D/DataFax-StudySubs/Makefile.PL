# ExtUtils::AutoInstall Bootstrap Code, version 4.
BEGIN {
    my $p='ExtUtils::AutoInstall';
    my $v=.30;
    eval "use $p $v; 1" or
    ($ENV{PERL_EXTUTILS_AUTOINSTALL} !~ 
        /--(?:default|skip|testonly)/ and (-t STDIN) or
    eval "use ExtUtils::MakeMaker;
        WriteMakefile('PREREQ_PM'=>{'$p',$v}); 1" and
    exit) and
    print "==> $p $v needed. Install it from CPAN? [Y/n] " and
    <STDIN> !~ /^n/i and
    print "*** Fetching $p\n" and
    do {
        eval {require CPANPLUS; CPANPLUS::install $p};
        eval "use $p $v; 1" or
            eval { require CPAN; CPAN::install $p };
        eval "use $p $v; 1" or
            die "Please install $p $v manually first...\n"
    }
}

use lib 'inc';
# pre-install handler; takes $module_name and $version
sub MY::preinstall  { return 1; }   # return false to skip install

# post-install handler; takes $module_name, $version, and $success
sub MY::postinstall { return 0 }
use ExtUtils::AutoInstall (
    -version        => '0.40',
);
WriteMakefile(
    ABSTRACT        => 'DataFax common sub routines' ,
    NAME            => 'DataFax::StudySubs'          ,
    DISTNAME        => 'DataFax-StudySubs-0.10.tar.gz',
    AUTHOR          => 'geotiger2001@yahoo.com'      ,
    VERSION         => 0.10                          ,
    PREREQ_PM       => {'Test::More' => 0.45,'Test::Harness' => 0.1,},
);
