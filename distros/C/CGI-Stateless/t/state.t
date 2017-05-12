use Test::More tests => 3;

use CGI::Stateless;

sub request {
    my ($stdin, $env) = @_;
    local *STDIN;
    open STDIN, '<', \$stdin or die "open STDIN: $!\n";
    local %ENV = %{$env};
    local $CGI::Q = CGI::Stateless->new();
    return CGI::param('test');
}

my $stdin = q{};
my $env = {
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'test=10',
};
is(request($stdin, $env), 10);
$env = {
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'some=other',
};
is(request($stdin, $env), undef);
$env = {
    REQUEST_METHOD => 'GET',
    QUERY_STRING => 'test=20',
};
is(request($stdin, $env), 20);

