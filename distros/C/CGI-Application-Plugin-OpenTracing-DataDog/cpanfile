requires        'CGI::Application::Plugin::OpenTracing', '>= v0.103.1';
requires        'OpenTracing::Implementation::DataDog',  '>= v0.42.1';

requires        'Carp';
requires        'Import::Into';
requires        'Readonly';

on 'test' => sub {
    requires    "Test::Most";
    requires    "Test::WWW::Mechanize::CGIApp";
    requires    "JSON::MaybeXS";
    requires    "HTTP::Response::Maker";
};

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

