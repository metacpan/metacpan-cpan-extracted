
requires "AnyEvent::Socket";
requires "AnyEvent::Handle";
requires "URI";

on 'test' => sub {
    requires 'Test::More' => "0";
    requires "Net::EmptyPort";
    requires "AnyEvent::Socket";
    requires "AnyEvent::Handle";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
