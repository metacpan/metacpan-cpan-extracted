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
};

on develop => sub {
    requires 'Test::Distribution';
    requires 'Test::Perl::Critic';
};
