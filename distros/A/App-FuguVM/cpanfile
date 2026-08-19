# NOTE: deps/*.txt with 'make deps' is the authoritative dependency
# list. This file exists for development convenience and carton
# compatibility.
#
# The Fugu library itself installs from its latest GitHub release
# through the dist line of deps/*.txt, not from CPAN.

# Fugu::SSH drives libssh2 through this binding; fuguvm ssh needs it
requires 'Net::SSH2';

# Fugu::Proxy serves the image cache. It uses HTTP::Request and
# HTTP::Response, which the HTTP::Message distribution provides, and
# URI.
requires 'HTTP::Daemon';
requires 'HTTP::Message';
requires 'LWP::UserAgent';
requires 'URI';

on 'test' => sub {
	requires 'Perl::Critic';
	requires 'Perl::Tidy';
};
