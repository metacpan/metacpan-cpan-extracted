#!perl

on runtime => sub {

    requires 'File::pushd';
    requires 'Lingua::Boolean::Tiny';
    requires 'List::Util' => 1.24;
    requires 'Log::Any';
    requires 'Path::Tiny' => 0.018;
    requires 'Try::Tiny';
    requires 'failures';
    requires 'custom::failures';

};

on test => sub {

    requires 'Test::More';
    requires 'Test::Fatal';
    requires 'Path::Tiny' => 0.018;
    requires 'File::pushd';
    requires 'Test::TempDir::Tiny';
    requires 'Log::Any';
    requires 'Log::Any::Test';

};

on develop => sub {

    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::AutoLicense';
    requires 'Test::CPAN::Changes';
    requires 'Test::NoBreakpoints';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Perl::Critic';

};
