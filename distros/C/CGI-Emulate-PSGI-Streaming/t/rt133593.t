#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Plack::Util;
use Encode;
use CGI::Parse::PSGI::Streaming;

sub _parse {
    my $output = shift;
    my $r;
    my $responder = sub {
        my ($response) = @_;
        $r = $response;
        return Plack::Util::inline_object(
            write => sub { push @{$r->[2]}, shift },
            close => sub {},
        );
    };
    my $stdout = CGI::Parse::PSGI::Streaming::parse_cgi_output_streaming_fh(
        $responder,
    );
    binmode $stdout, ':encoding(UTF-8)';
    print {$stdout} $output;

    my $h = HTTP::Headers->new;
    while (my($k, $v) = splice @{$r->[1]}, 0, 2) {
        $h->header($k, $v);
    }
    return $r, $h;
}

my $body = join '', map { chr($_) }
    (0x20000 .. 0x2FFF0)
;
my ($r, $h) = _parse(<<"EOF");
Status: 200
Content-type: text/plain

$body
EOF

is(
    length($r->[2][0]),
    length(encode('UTF-8',$body,Encode::LEAVE_SRC)) + 1, # the newline
    'non-ascii strings should pass correctly',
);

done_testing;

