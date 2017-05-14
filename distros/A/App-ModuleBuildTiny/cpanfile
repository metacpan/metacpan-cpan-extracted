requires 'Archive::Tar';
requires 'CPAN::Meta';
requires 'CPAN::Meta::Merge';
requires 'CPAN::Meta::Prereqs::Filter';
requires 'CPAN::Upload::Tiny';
requires 'Data::Section::Simple';
requires 'Encode';
requires 'Exporter', '5.57';
requires 'ExtUtils::Manifest';
requires 'File::Path';
requires 'File::Slurper';
requires 'File::Temp';
requires 'Getopt::Long', '2.36';
requires 'JSON::PP';
requires 'Module::CPANfile';
requires 'Module::Metadata';
requires 'Module::Runtime';
requires 'Parse::CPAN::Meta';
requires 'Pod::Simple::Text', '3.23';
requires 'Software::LicenseUtils';
requires 'Text::Template';
requires 'perl', '5.010';

on configure => sub {
    requires 'Module::Build::Tiny', '0.039';
};

on test => sub {
    requires 'Test::More';
};
