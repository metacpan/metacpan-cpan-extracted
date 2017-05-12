use ExtUtils::MakeMaker;

WriteMakefile (
    'NAME'             => 'App::nrun',
    'VERSION_FROM'     => 'lib/NRun/Version.pm',
    'INSTALLSCRIPT'    => 'blib/bin',
    'EXE_FILES'        => [
        'bin/nrun',
        'bin/ncopy',
    ],
    'LICENSE' => 'gpl',
    'PREREQ_PM' => {
        "Date::Format" => 0,
        "YAML"         => 0,
    },
);

sub MY::postamble {

    my $postamble =
    "install_vendor :: etc/nrunrc\n" .
    "\tmkdir -p \$(DESTDIR)/etc\n" .
    "\tcp etc/nrunrc \$(DESTDIR)/etc/nrunrc\n\n" .
    "install :: etc/nrunrc\n" .
    "\tmkdir -p \$(DESTDIR)/etc\n" .
    "\tcp etc/nrunrc \$(DESTDIR)/etc/nrunrc\n";

    return $postamble;
}

