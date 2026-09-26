requires 'Carp';
requires 'Cwd';
requires 'Data::Dumper';
requires 'Exporter';
requires 'ExtUtils::MM';
requires 'ExtUtils::MakeMaker';
requires 'File::Basename';
requires 'File::Copy';
requires 'File::Spec';
requires 'File::Temp';
requires 'FindBin';
requires 'IO::File';
requires 'Software::LicenseUtils';
requires 'Tie::File';
requires 'base';
requires 'perl', '5.008';
requires 'strict';
requires 'vars';
requires 'warnings';

on configure => sub {
    requires 'perl', '5.008';
    requires 'ExtUtils::MakeMaker';
    requires 'Tie::File';
    requires 'version';
    suggests 'ASPEER::MakeMaker::Markdown::Pod', '1.010';
};

on test => sub {
    requires 'File::Path';
    requires 'File::Temp';
    requires 'Test::More';
};
