requires 'perl', '5.008001';
requires 'Ark';
requires 'Net::OpenID::Consumer';
requires 'LWPx::ParanoidAgent';
requires 'OAuth::Lite';

suggests 'DBIx::Class';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    requires 'Digest::SHA1';
};
