use strict;
use warnings;
use Test::More;
use CGI;
use CGI::PSGI;

my $env = { REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.0' };
my $q = CGI::PSGI->new($env);

# positional args: type, status, cookie, target, expires, nph, charset,
# attachment, p3p, then extra header lines
sub hdr { my @extra = @_; [ $q->psgi_header('text/plain', '', ('') x 7, @extra) ]->[1] }

# CGI.pm 5.02's header() for the same arguments, as name/value pairs
sub cgi_hdr {
    my @extra = @_;
    my $h = CGI->new({})->header('text/plain', '', ('') x 7, @extra);
    return [ map { /^([^:]+):[ \t]*(.*?)[ \t]*$/ ? ($1, $2) : () } split /\r\n/, $h ];
}

for my $case (
    [ 'X-Foo: bar',          [ 'X-Foo' => 'bar' ] ],
    [ 'x-foo: bar',          [ 'X-foo' => 'bar' ] ],
    [ 'X-Foo:bar  ',         [ 'X-Foo' => 'bar' ] ],
    [ 'X-Foo: a: b',         [ 'X-Foo' => 'a: b' ] ],
    [ 'X-Foo:',              [ 'X-Foo' => '' ] ],
    [ 'x_foo=bar',           [ 'X_foo' => 'bar' ] ],
    [ 'Link: </a>; rel=pre', [ 'Rel' => 'pre' ] ],  # name=value wins, as in CGI.pm
) {
    my($line, $want) = @$case;
    my $want_all = [ @$want, 'Content-Type' => 'text/plain' ];
    is_deeply hdr($line), $want_all, "positional '$line'";
    is_deeply hdr($line), cgi_hdr($line), "positional '$line' matches CGI.pm";
}

is_deeply hdr('X-A: 1', 'X-B: 2'), [ 'X-A' => 1, 'X-B' => 2, 'Content-Type' => 'text/plain' ],
    'several lines, in order';

is_deeply hdr("X-Foo: a\r\n b"), [ 'X-Foo' => 'a b', 'Content-Type' => 'text/plain' ],
    'folded line is unfolded';

# lines that can't be a header are skipped
for my $line ('nocolon', 'Foo Bar: baz', ' X-Lead: 1', ': x', '') {
    is_deeply hdr($line), [ 'Content-Type' => 'text/plain' ], "'$line' skipped";
}

# header injection
for my $line ("X-Foo: bar\r\nSet-Cookie: evil=1", "X-Foo: bar\nEvil: 1", "X-Foo: bar\rEvil: 1",
              "Foo\r\nSet-Cookie: evil=1", "nocolon\nEvil: 1", "x=1\r\nEvil: 1") {
    (my $name = $line) =~ s/\r/\\r/g; $name =~ s/\n/\\n/g;
    eval { hdr($line) };
    like $@, qr/contains a newline/, "newline in '$name' dies";
}

done_testing;
