use ExtUtils::MakeMaker;
die "OS unsupported - Only Visual C/Intel C family of compilers are supported"
    if $Config::Config{cc} !~ /\b(?:cl|icl)/; #MSVC can come as clarm.exe, icl=Intel C

WriteMakefile(
    NAME              => 'Win32::PEPM',
    DISTNAME          => 'Acme-Win32-PEPM',
    VERSION_FROM      => 'lib/Win32/PEPM.pm',
    PREREQ_PM         => {'File::Slurp' => 0},
    ABSTRACT_FROM     => 'lib/Win32/PEPM.pm',
    AUTHOR            => 'Daniel Dragan <bulkdd@cpan.org>',
    LICENSE           => 'perl',
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I.',
);
