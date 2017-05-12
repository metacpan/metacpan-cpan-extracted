use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok 'CGI::Header::Extended';
}

subtest '#get' => sub {
    my $header = CGI::Header::Extended->new(
        header => {
            foo => 'bar',
            bar => 'baz',
        },
    );
    is_deeply [ $header->get(qw/foo bar/) ], [qw/bar baz/];
};

subtest '#set' => sub {
    my $header = CGI::Header::Extended->new;
    is_deeply [ $header->set(foo => 'bar', bar => 'baz') ], [qw/bar baz/];
    is_deeply $header->header, { foo => 'bar', bar => 'baz' };
};

subtest '#delete' => sub {
    my $header = CGI::Header::Extended->new(
        header => {
            foo => 'bar',
            bar => 'baz',
            baz => 'qux',
        },
    );
    is_deeply [ $header->delete(qw/foo bar/) ], [qw/bar baz/];
    is_deeply $header->header, { baz => 'qux' };
};
