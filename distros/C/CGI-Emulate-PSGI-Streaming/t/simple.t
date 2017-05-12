#!perl
use strict;
use warnings;
use CGI;
use CGI::Emulate::PSGI::Streaming;
use Plack::Util;
use Test::More tests=>13;
use Test::Deep;
use Data::Dump 'pp';

my $fh = select;

my $handler = CGI::Emulate::PSGI::Streaming->handler(
    sub {
        binmode STDOUT, ":utf8";
        select STDERR;
        my $special=chr(4242);
        print STDOUT "Content-Type: text/html; charset=utf-8\r\n";
        print STDOUT "\r\n";
        print "first error\n";
        print STDOUT "first block $special\r\n";
        sleep 1;
        print "second error\n";
        print STDOUT "second block $special\r\n";
    }
);

my $err;
open my $in, '<', \do { my $body = '' };
open my $errors, '>', \$err;
my $res = $handler->(
    +{
        'psgi.input'   => $in,
        REMOTE_ADDR    => '192.168.1.1',
        REQUEST_METHOD => 'GET',
        'psgi.errors'  => $errors,
    }
);


my $post_fh = select;

is(ref($res),'CODE','::Streaming should return a coderef');
is($post_fh,$fh,'SelectSaver worked before callback');

$res->(
    sub {
        my ($response) = @_;
        cmp_deeply(
            $response,
            [
                200,
                [
                    'Content-Type' => 'text/html; charset=utf-8',
                ],
            ],
            'the responder should get a 200 status and content-type header',
        );

        $post_fh = select;
        is($post_fh,$fh,'SelectSaver worked after headers');

        my $step=0;
        my $o = Plack::Util::inline_object(
            write => sub {
                my ($data) = @_;

                $post_fh = select;
                is($post_fh,$fh,'SelectSaver worked during output');

                if ($step == 0) {
                    is(
                        $data,"first block \xe1\x82\x92\r\n",
                        'first print should have the first block',
                    ) or note pp $data;
                    is(
                        $err,"first error\n",
                        'first print STDERR should have the first error',
                    );
                }
                else {
                    is(
                        $data,"second block \xe1\x82\x92\r\n",
                        'second print should have the second block',
                    ) or note pp $data;
                    is(
                        $err,"first error\nsecond error\n",
                        'second print STDERR should have the second error',
                    );
                }
                ++$step;
            },
            close => sub {
                $post_fh = select;
                is($post_fh,$fh,'SelectSaver worked in close');

                is($step,2,'two blocks should have been printed');
            },
        );
        return $o;
    },
);

$post_fh = select;
is($post_fh,$fh,'SelectSaver worked at the end');
