requires 'perl', '5.008005';
requires 'strict';
requires 'warnings';
requires 'Getopt::Long', '2.42';
requires 'Pod::Usage';
requires 'IO::Interactive::Tiny';
requires 'HTML::FromANSI::Tiny';

on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Output';
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
