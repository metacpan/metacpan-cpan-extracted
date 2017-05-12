requires 'Class::Inspector';
requires 'Class::Unload';
requires 'Encode';
requires 'Getopt::Long';
requires 'Log::Dump', '0.10';
requires 'Path::Tiny';
requires 'Pod::Simple';
requires 'String::CamelCase';
requires 'Term::Encoding';
requires 'Try::Tiny';

on test => sub {
    requires 'Test::Classy', '0.04';
    requires 'Test::More', '0.47';
    requires 'Test::UseAllModules', '0.15';
};

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile' => '0.07';
};
