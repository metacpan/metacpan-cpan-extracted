requires 'perl', '5.012003';

requires 'CPANPLUS';
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
requires 'parent';
requires 'Pod::Find';
requires 'Pod::Simple';
requires 'POSIX';
requires 'Text::Wrap';
requires 'version', '0.77';

on 'test' => sub {
    requires 'Test::More', '0.96';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::Plugin::CopyFilesFromBuild';
    requires 'Dist::Zilla::Plugin::LicenseFromModule';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
};
