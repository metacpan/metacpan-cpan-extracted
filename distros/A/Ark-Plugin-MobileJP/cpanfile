requires 'perl', '5.008001';
requires 'Ark';
requires 'Encode::JP::Mobile';
requires 'HTTP::MobileAgent';
requires 'HTTP::MobileAgent::Plugin::Charset';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
    requires 'HTTP::Request::Common';
};
