use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'DBIx::Array::Connect',
    VERSION_FROM => 'lib/DBIx/Array/Connect.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/DBIx/Array/Connect.pm',
    PREREQ_PM    => {
                     'Test::Simple'        => 0.44,
                     'Package::New'        => 0,
                     'Config::IniFiles'    => 0,
                     'Path::Class'         => 0,
                     'DBIx::Array'         => 0.14,
    $^O eq "MSWin32" ?
                   ( 'Win32'               => 0  ):
                   ( 'Sys::Path'           => 0  ),
                    },
);
