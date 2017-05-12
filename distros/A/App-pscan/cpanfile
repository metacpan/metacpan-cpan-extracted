requires 'App::CLI';
requires 'App::CLI::Command';
requires 'App::CLI::Command::Help';
requires 'Net::DNS::Resolver';
requires 'Net::IP';
requires 'POE';
requires 'POE::Component::Client::Ping';
requires 'POE::Component::Client::TCP';
requires 'POE::Filter::Stream';
requires 'POE::Wheel::ReadWrite';
requires 'POE::Wheel::SocketFactory';
requires 'Term::ANSIColor';
requires 'URI';
requires 'perl', '5.008_005';

on configure => sub {
    requires 'Module::Build::Tiny', '0.034';
};

on test => sub {
    requires 'Test::More';
};
