#!/usr/bin/perl

use ExtUtils::MakeMaker;

$PACKAGE = 'D::oh::Year';
($PACKAGE_FILE) = $PACKAGE =~ /::([^:]+)/;
$LAST_API_CHANGE = 0;

eval "require $PACKAGE";

unless ($@) { # Make sure we did find the module.
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

WriteMakefile(
    NAME                => $PACKAGE,
    VERSION_FROM        => "lib/D/oh/Year.pm", # finds $VERSION
    PREREQ_PM           => {
        overload    => 0,
        fields      => 1.02,  # fields::new()
        'Test::More'=> 0.47,
    },
);
