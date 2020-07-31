requires 'perl', '5.006001';

requires 'base';
requires 'Config';
requires 'CPANPLUS', '0.9166';
requires 'Cwd';
requires 'ExtUtils::Install';
requires 'File::Find';
requires 'File::Spec';
requires 'File::Temp';
requires 'IO::Compress::Gzip';
requires 'IPC::Cmd';
requires 'Locale::Maketext::Simple';
requires 'Module::CoreList', '2.32';
requires 'Module::Pluggable';
requires 'Params::Check';
requires 'POSIX';
requires 'Text::Wrap';
requires 'version', '0.77';

conflicts 'Module::Build', '< 0.36';

on 'test' => sub {
    requires 'Test::More', '0.96';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::Plugin::CopyFilesFromBuild';
    requires 'Dist::Zilla::Plugin::LicenseFromModule';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
    requires 'Pod::Coverage::TrustPod';
};
