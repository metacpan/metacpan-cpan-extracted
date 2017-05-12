requires 'perl', '5.010';

requires 'AnyEvent';
requires 'AnyEvent::RabbitMQ';
requires 'Promises';
requires 'Moose';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Module::Build::Tiny';
    requires 'Minilla';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod';
    requires 'Test::Spellunker';
    requires 'Version::Next';
    requires 'CPAN::Uploader';
};
