use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'ARS::Simple',
    AUTHOR           => q{Greg George <gng@cpan.org>},
    VERSION_FROM     => 'lib/ARS/Simple.pm',
    ABSTRACT_FROM    => 'lib/ARS/Simple.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {'Config.PL' => 'config'},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        ARS     => 1.68,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'ARS-Simple-*' },
);

makeTestConfig();

if (!$ENV{AUTOMATED_TESTING})
{
    print "
    Type 'make' (windows: 'nmake' or 'dmake') to build ARS::Simple.
    Type 'make test' to test ARS::Simple before installing.
    Type 'make install' to install ARS::Simple.

    ";
}

exit 0;


sub makeTestConfig
{
    my ($server, $user, $password);
    my ($i, $u, $p) = ('', $ENV{USERNAME}, '');

    if(-e './t/config.cache')
    {
        do './t/config.cache';
        $i = &CCACHE::server;
        $u = &CCACHE::user;
        $p = &CCACHE::password;
    }

    print "=== ARS::Simple 'make test' configuration. ===

Test on your own dev system where you know the user you select below
is in the administrator group.

Please enter the following information. This information will be
recorded in ./t/config.cache.  YOU SHOULD REMOVE this file once
you have finished testing as the data is in plain text.

As an alternate, skip testing and install and start trying it out!

If you want to skip the 'make test' step, just hit ENTER
three times. You can configure it later by either re-running
'perl Makefile.PL' or by editting ./t/config.cache

Fair warning: you probably don't want to run 'make test' against a
production Remedy ARS server.

";

    $server = prompt("The Remedy server hostname (or IP Address)", $i);
    if ($server eq '') { $server = $i if ($i ne ''); }

    $user = prompt("Remedy user with admin", $u);
    if($user eq '') { $user = $u if ($u ne ''); }

    $password = prompt("Password", $p);;
    if($password eq '') { $password = $p if ($p ne ''); }

    open (FD, '>', './t/config.cache') || die "open of './t/config.cache' failed: $!";
    print FD "package CCACHE;\n";
    print FD "\# enter your remedy server, username and password below.\n\n";
    print FD qq{sub server { '$server' ; }\n};
    print FD qq{sub user     { '$user' ; }\n};
    print FD qq{sub password { '$password' ; }\n};
    print FD "1;\n";
    close(FD);
}