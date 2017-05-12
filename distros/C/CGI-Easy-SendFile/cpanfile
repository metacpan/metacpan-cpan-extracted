requires 'perl', '5.010001';

requires 'CGI::Easy';
requires 'CGI::Easy::Util';
requires 'Export::Attrs';
requires 'List::Util';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'CGI::Easy::Headers';
    requires 'Test::More';
    recommends 'Pod::Coverage', '0.18';
    recommends 'Test::CheckManifest', '0.9';
    recommends 'Test::Perl::Critic';
    recommends 'Test::Pod', '1.22';
    recommends 'Test::Pod::Coverage', '1.08';
};
