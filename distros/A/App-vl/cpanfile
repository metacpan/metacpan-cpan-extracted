requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';

requires 'Getopt::Long', '2.42';
requires 'Pod::Usage', '1.30';
requires 'IO::Pager';

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'Capture::Tiny';
};

on 'configure' => sub {
    requires 'Module::Build' , '0.40';
    requires 'Module::Build::Pluggable';
    requires 'Module::Build::Pluggable::CPANfile';
};

on 'develop' => sub {
    recommends 'Test::Perl::Critic';
    recommends 'Test::Pod::Coverage';
    recommends 'Test::Pod';
    recommends 'Test::NoTabs';
    recommends 'Test::Perl::Metrics::Lite';
    recommends 'Test::Vars';
};
