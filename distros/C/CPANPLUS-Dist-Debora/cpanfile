requires 'perl', '5.016';

requires 'Archive::Tar';
requires 'Carp';
requires 'Config';
requires 'CPAN::Meta';
requires 'CPANPLUS', '0.9166';
requires 'Cwd';
requires 'Encode';
requires 'English';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'IPC::Cmd';
requires 'Module::CoreList', '2.32';
requires 'Module::Pluggable', '2.4';
requires 'Net::Domain';
requires 'Pod::Simple';
requires 'POSIX';
requires 'Scalar::Util';
requires 'Software::License', '0.103014';
requires 'Text::Template', '1.22';
requires 'Text::Wrap';
requires 'parent';
requires 'utf8';
requires 'version', '0.77';
requires 'warnings';

conflicts 'Module::Build', '< 0.36';

on 'runtime' => sub {
    requires 'CPANPLUS::Dist::Build';
};

on 'test' => sub {
    requires 'Test::More', '0.96';
    requires 'Test::MockObject', '1.07';
    requires 'lib';
    requires 'open';
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Dist::Zilla::Plugin::CopyFilesFromBuild';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
    requires 'Dist::Zilla::Plugin::Test::Kwalitee';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Kwalitee', '1.21';
    requires 'Test::Pod::Coverage';
};
