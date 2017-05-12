#!perl

requires 'Getopt::Long' => 2.24;
requires 'Scalar::Util';
requires 'Params::Validate';
requires 'Pod::Usage';
requires 'File::Temp';
requires 'File::Basename';
requires 'Module::Find';
requires 'File::Spec::Functions';
requires 'IPC::System::Simple';
requires 'Capture::Tiny' => 0.09;
requires 'Scalar::Util';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Fatal';
    requires 'Env::Path';
};

on develop => sub {

    requires 'Module::Install';
    requires 'Module::Install::AuthorRequires';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::AutoLicense';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::ReadmeFromPod';

    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';
    requires 'Test::CPAN::Changes';
    requires 'Test::CPAN::Meta';
    requires 'Test::CPAN::Meta::JSON';

};
