requires 'perl', '5.020';
requires 'Crypt::URandom';
requires 'Digest::SHA';
requires 'GD::Barcode';
requires 'HTTP::Tiny';
requires 'JSON::MaybeXS';
requires 'MIME::Base64', '3.11';
requires 'Moo';
requires 'Test::More', '0.96';
requires 'Type::Tiny';
requires 'namespace::autoclean', '0.16';

recommends 'HTTP::Message';
recommends 'IO::Socket::SSL';

on test => sub {
    requires 'HTTP::Message';
    requires 'Path::Tiny';
    requires 'Plack';
    requires 'Test::TCP';
};
