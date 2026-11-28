use strict;
use warnings;
use Test::More;
use CGI::PSGI;

# psgi.input whose read() returns at most $max bytes per call, like sysread
{
    package ShortInput;
    sub new { my($c, $data, $max) = @_; bless { data => $data, pos => 0, max => $max, calls => 0 }, $c }
    sub read {
        my $self = shift;
        my(undef, $len, $off) = @_;
        $self->{calls}++;
        return $self->{error} if exists $self->{error} && $self->{pos} >= $self->{error_at};
        $len = $self->{max} if $len > $self->{max};
        my $chunk = substr($self->{data}, $self->{pos}, $len);
        $self->{pos} += length $chunk;
        $off = 0 unless defined $off;
        $_[0] = '' unless defined $_[0];
        $_[0] .= "\0" x ($off - length $_[0]) if $off > length $_[0];
        substr($_[0], $off) = $chunk;
        return length $chunk;
    }
}

sub env_for {
    my($type, $body, $input) = @_;
    return {
        REQUEST_METHOD  => 'POST',
        SERVER_PROTOCOL => 'HTTP/1.0',
        CONTENT_TYPE    => $type,
        CONTENT_LENGTH  => length $body,
        'psgi.input'    => $input || ShortInput->new($body, 3),
    };
}

for my $max (1, 3, 7) {
    my $body = 'a=12345&b=2';
    my $q = CGI::PSGI->new(env_for('application/x-www-form-urlencoded', $body, ShortInput->new($body, $max)));
    is $q->param('a'), '12345', "urlencoded a, $max-byte reads";
    is $q->param('b'), '2',     "urlencoded b, $max-byte reads";
}

{
    my $body = '<x>hello world</x>';
    my $q = CGI::PSGI->new(env_for('application/xml', $body));
    local $CGI::LIST_CONTEXT_WARN = 0;
    is $q->param('XForms:Model'), $body, 'application/xml body read in full';
}

{
    my $body = join "\r\n",
        '------BOUNDARY',
        'Content-Disposition: form-data; name="upload_foo"; filename="foo.txt"',
        'Content-Type: text/plain',
        '',
        'FOO' x 2000,
        '------BOUNDARY',
        'Content-Disposition: form-data; name="bar"',
        '',
        'BAR',
        '------BOUNDARY--',
        '';
    for my $max (1, 3, 100) {
        my $q = eval { CGI::PSGI->new(env_for('multipart/form-data; boundary=----BOUNDARY', $body, ShortInput->new($body, $max))) };
        is $@, '', "multipart doesn't die, $max-byte reads";
        next unless $q;
        is $q->param('bar'), 'BAR', "multipart field, $max-byte reads";
        my $fh = $q->upload('upload_foo');
        is scalar(do { local $/; <$fh> }), 'FOO' x 2000, "multipart upload, $max-byte reads";
    }
}

# read_from_client itself: offset, EOF and errors
{
    my $q = CGI::PSGI->new({ REQUEST_METHOD => 'GET', SERVER_PROTOCOL => 'HTTP/1.0' });

    local $q->{psgi_env}{'psgi.input'} = ShortInput->new('abcdefgh', 3);
    my $buf = 'XY';
    is $q->read_from_client(\$buf, 5, 2), 5, 'reads the full length';
    is $buf, 'XYabcde', 'at the offset';
    is $q->read_from_client(\$buf, 10, length $buf), 3, 'stops at EOF';
    is $buf, 'XYabcdefgh';
    is $q->read_from_client(\$buf, 10, length $buf), 0, 'returns 0 at EOF';

    my $in = ShortInput->new('abcdefgh', 3);
    @$in{qw(error error_at)} = (undef, 3);
    local $q->{psgi_env}{'psgi.input'} = $in;
    $buf = '';
    is $q->read_from_client(\$buf, 8, 0), 3, 'returns what was read before an error';
    is $buf, 'abc';
    is $q->read_from_client(\$buf, 8, 3), undef, 'returns undef on an error with nothing read';
    ok $in->{calls} < 10, "doesn't loop on an error";
}

done_testing;
