requires 'perl', '5.008001';
requires 'Digest::SHA';
requires 'Amon2::Util';

on 'test' => sub {
    requires 'Test::More', '0.98';
    # Amon2::Lite requires this module.
    # I should not include it in testing requirements.
    # I should use Test::Requires instead.
    # requires 'Amon2::Lite';
    requires 'Test::Requires';
    requires 'HTTP::Session::Store::OnMemory';
};

