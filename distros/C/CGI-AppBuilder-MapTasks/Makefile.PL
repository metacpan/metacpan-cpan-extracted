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

# pre-install handler; takes $module_name and $version
sub MY::preinstall  { return 1; }   # return false to skip install

# post-install handler; takes $module_name, $version, and $success
sub MY::postinstall { return 0 }
use ExtUtils::AutoInstall (
    -version        => '0.40',
);
WriteMakefile(
    ABSTRACT        => 'CGI::AppBuilder::PLSQL - Oracle PL/SQL Procedures',
    NAME            => 'CGI::AppBuilder::MapTasks'   ,
    DISTNAME        => 'CGI-AppBuilder-MapTasks-0.12.tar.gz',
    AUTHOR          => 'hanming.tu@gmail.com'        ,
    VERSION         => 0.12                          ,
    PREREQ_PM       => {Test::More => 0.45,Test::Harness => 0.1,},
);
