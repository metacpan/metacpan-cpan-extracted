
requires "Carp";
requires "Try::Tiny";
requires "AnyEvent::Handle";
requires "AnyEvent::WebSocket::Client", "0.37";
requires "Protocol::WebSocket::Handshake::Server";
recommends "Net::SSLeay";

on "test" => sub {
    requires "Test::More";
    requires "Test::Memory::Cycle";
    requires "Test::Requires";
    requires "AnyEvent";
    requires "AnyEvent::Socket";
    requires "AnyEvent::Handle";
    requires "AnyEvent::WebSocket::Client", "0.37";
    requires "Scalar::Util";
    requires "Try::Tiny";
    requires "Protocol::WebSocket::Handshake::Client";
    requires "Protocol::WebSocket::Frame";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
