requires 'perl', '5.014';

requires 'Carp';
requires 'Errno';
requires 'Import::Into';
requires 'IO::Handle';
requires 'IO::Socket::INET';
requires 'IO::Socket::UNIX';
requires 'JSON::MaybeXS';
requires 'Log::Any';
requires 'MIME::Base64';
requires 'Module::Runtime';
requires 'Moo';
requires 'namespace::clean';
requires 'overload';
requires 'Package::Stash';
requires 'Path::Tiny';
requires 'Scalar::Util';
requires 'Socket';
requires 'Types::Standard';

# Only the tcp:// transport with tls => 1 loads this, and it is loaded at the
# moment that connection is opened. It brings in Net::SSLeay, which is XS
# compiled against libssl; requiring it would make this client unbuildable
# where there are no OpenSSL headers, for the sake of a transport that the
# unix:// default -- local Docker, rootless Podman -- never uses.
recommends 'IO::Socket::SSL';

on test => sub {
    requires 'Exporter';
    requires 'Path::Tiny';
    requires 'Test::More';
};

# The drift checker under maint/ reads Docker's swagger from spec/ and the
# exceptions file beside itself. YAML::XS rather than YAML::PP is not a
# preference: YAML::PP 0.41 will not parse the file Docker publishes -- see
# the comment at the top of maint/spec-drift-check.pl. Nothing under lib/
# loads a YAML parser.
on develop => sub {
  requires 'YAML::XS';
};
