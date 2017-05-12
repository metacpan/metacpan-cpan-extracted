requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';
requires 'Config::CmdRC', '0.07';
requires 'Getopt::Long', '2.42';
requires 'Pod::Usage';

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'Capture::Tiny';
};

on 'configure' => sub {
    requires 'Module::Build' , '0.40';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};