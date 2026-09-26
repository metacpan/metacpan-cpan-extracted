requires 'ASPEER::MakeMaker', '1.010';
requires 'Cwd';
requires 'Digest::MD5';
requires 'Docbook::Convert', '1.010';
requires 'ExtUtils::Manifest';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Spec';
requires 'Markdown::Pod::Embed', '1.010';
requires 'perl', '5.010';
requires 'strict';
requires 'vars';
requires 'warnings';

on configure => sub {
    requires 'perl', '5.010';
    requires 'ExtUtils::MakeMaker';
    requires 'version';
};

on test => sub {
    requires 'File::Path';
    requires 'File::Temp';
    requires 'Test::More';
};
