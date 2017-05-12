use inc::Module::Install;

name           'CPAN-Index';
all_from       'lib/CPAN/Index.pm';
requires       'Carp'           => 0;
requires       'IO::Handle'     => 0;
requires       'IO::File'       => 0;
requires       'IO::Zlib'       => 0;
requires       'version'        => '0.59';
requires       'Params::Util'   => '0.20'; # _HANDLE(IO::Zlib)
requires       'Email::Address' => '1.80';
requires       'DBI'            => '1.50';
requires       'DBD::SQLite'    => '1.12';
requires       'DBIx::Class'    => '0.06002';
requires       'CPAN::Cache'    => '0.01';
build_requires 'Test::More'     => '0.47';
build_requires 'File::Spec'     => '0.80';
build_requires 'File::Copy'     => 0;
build_requires 'File::Remove'   => 0;

WriteAll;
