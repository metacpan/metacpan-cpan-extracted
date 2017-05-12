use inc::Module::Install;

# Define metadata
name           'Catalyst-Plugin-Authentication-Credential-GooglePlus';
all_from       'lib/Catalyst/Plugin/Authentication/Credential/GooglePlus.pm';

# Specific dependencies
requires        'Crypt::OpenSSL::X509';
requires        'JSON::WebToken';
requires        'IO::All';
requires        'JSON::MaybeXS';
requires        'MIME::Base64';
requires        'LWP::Simple';
requires        'Date::Parse';
requires        'Try::Tiny';
requires        'strictures';
requires        'LWP::Protocol::https';
requires        'Crypt::OpenSSL::RSA';

no_index        'directory'   => 'example';

WriteAll;
