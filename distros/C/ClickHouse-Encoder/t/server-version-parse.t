use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use HTTP::Tiny;

# server_version parses whatever `select version()` returns. Drive it
# with a captive HTTP::Tiny->get so a range of real-world version
# strings can be checked without a server.

sub with_version_response {
    my ($content, $code) = @_;
    no warnings qw(redefine once);
    local *HTTP::Tiny::get = sub {
        return { success => 1, status => 200,
                 content => $content, headers => {} };
    };
    return $code->();
}

# Plain four-part version.
with_version_response("24.8.1.2\n", sub {
    my $v = ClickHouse::Encoder->server_version(host => 'x');
    is($v->{major}, 24, 'major');
    is($v->{minor}, 8,  'minor');
    is($v->{patch}, 1,  'patch');
    is($v->{build}, 2,  'build');
    is($v->{raw},   '24.8.1.2', 'raw trimmed');
});

# Version string with a build-type suffix (common in official builds).
with_version_response("23.3.2.37 (official build)\n", sub {
    my $v = ClickHouse::Encoder->server_version(host => 'x');
    is($v->{major}, 23, 'major from suffixed string');
    is($v->{minor}, 3,  'minor from suffixed string');
    is($v->{patch}, 2,  'patch from suffixed string');
    is($v->{build}, 37, 'build from suffixed string');
});

# Three-part version: build defaults to 0.
with_version_response("25.1.5\n", sub {
    my $v = ClickHouse::Encoder->server_version(host => 'x');
    is($v->{major}, 25, 'three-part major');
    is($v->{build}, 0,  'missing build component defaults to 0');
});

# List context returns the numeric parts plus the raw string.
with_version_response("24.8.1.2\n", sub {
    my @v = ClickHouse::Encoder->server_version(host => 'x');
    is_deeply(\@v, [24, 8, 1, 2, '24.8.1.2'],
              'list context: (major, minor, patch, build, raw)');
});

# A failed HTTP response croaks rather than returning a bogus version.
{
    no warnings qw(redefine once);
    local *HTTP::Tiny::get = sub {
        return { success => 0, status => 500,
                 content => 'boom', headers => {} };
    };
    local $@;
    eval { ClickHouse::Encoder->server_version(host => 'x') };
    like($@, qr/select version\(\) failed/, 'HTTP failure croaks');
}

done_testing();
