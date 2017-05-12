use strict;
use warnings;

use Test::More;

BEGIN {
    eval q{ require Test::TCP } or plan skip_all => 'Could not require Test::TCP';
    eval q{ require HTTP::Server::Simple::CGI } or plan skip_all => 'Could not require HTTP::Server::Simple::CGI';
}

{
    package HTTP::Server::Simple::Test;
    our @ISA = 'HTTP::Server::Simple::CGI';

    sub print_banner { }

    sub handle_request {
        my ($self, $cgi) = @_;

        if($cgi->url(-path_info=>1) =~ m,/unavailable$,) {
            print "HTTP/1.0 503 Service Unavailable\r\n";
            print "\r\n";
            return;
        } elsif($cgi->url(-path_info=>1) =~ m,/notfound$,) {
            print "HTTP/1.0 404 Not found\r\n";
            print "\r\n";
            return;
        } elsif($cgi->url(-path_info=>1) =~ m,/redirect(\d)$,) {
            my $count = $1; 
            if($count < 3) {
                ++$count;
                print "HTTP/1.0 301 Moved Permanently\r\n";
                print "Location: /redirect$count\r\n";
                print "\r\n";
                return;
            }
        }
 
        print "HTTP/1.0 200 OK\r\n";
        print "Content-Type: text/html\r\n";
        print "Set-Cookie: test=abc; path=/\r\n";
        print "\r\n";
        print <<__HTML__;
<html>
  <head>
    <title>Test Web Page</title>
    <base href="http://www.example.com/">
  </head>
  <body>
    <p>blahblahblha</p>
  </body>
</html>
__HTML__
    }
}

BEGIN { plan tests => 14; }

BEGIN { use_ok('AnyEvent::HTTP::LWP::UserAgent::Determined') }

use HTTP::Headers;
use HTTP::Request;
use HTTP::Request::Common qw( GET );

sub timings {
  my $self = shift;
  # copied from module, line 20
  my(@timing_tries) = ( $self->timing() =~ m<(\d+(?:\.\d+)*)>g );
}

note "Hello from ", __FILE__, "\n";
note "AnyEvent::HTTP::LWP::UserAgent::Determined v$AnyEvent::HTTP::LWP::UserAgent::Determined::VERSION\n";
note "LWP::UserAgent v$LWP::UserAgent::VERSION\n";
note "LWP v$LWP::VERSION\n" if $LWP::VERSION;

Test::TCP::test_tcp(
    server => sub {
        my $port = shift;
        my $server = HTTP::Server::Simple::Test->new($port);
        $server->run;
    },
    client => sub {
        my $port = shift;
        my $browser = AnyEvent::HTTP::LWP::UserAgent::Determined->new;
        ok 1;

        my @error_codes = qw(408 500 502 503 504);
        is_deeply( [sort keys %{$browser->codes_to_determinate}], \@error_codes );
        # for unknown host/port, 595 is returned by AnyEvent::HTTP::LWP::UserAgent instead of 500.
        $browser->codes_to_determinate->{595} = 1;

        my $before_count = 0;
        my  $after_count = 0;

        $browser->before_determined_callback( sub {
            note " /Trying ", $_[4][0]->uri, " at ", scalar(localtime), "...\n";
            ++$before_count;
        });
        $browser->after_determined_callback( sub {
            note " \\Just tried ", $_[4][0]->uri, " at ", scalar(localtime), ".  ",
            ($after_count < scalar(timings($browser)) ? "Waiting " . (timings($browser))[$after_count] . "s." : "Giving up."), "\n";
            ++$after_count;
        });

        my $resp = $browser->request(GET "http://localhost:$port/redirect0");
        ok $resp->is_success;
        note "That gave: ", $resp->status_line, "\n";
        note "Before_count: $before_count\n";
        cmp_ok( $before_count, '==', 4 );
        note "After_count: $after_count\n";
        cmp_ok(  $after_count, '==', 4 );

        $before_count = 0;
        $after_count = 0;

        note "Trying 503\n";
        $browser->timing('1,2,3');
        is($browser->timing, '1,2,3');
        $resp = $browser->request( GET "http://localhost:$port/unavailable" );
        ok !$resp->is_success;
        note "That gave: ", $resp->status_line, "\n";
        note "Before_count: $before_count\n";
        cmp_ok $before_count, '==', 4;
        note "After_count: $after_count\n";
        cmp_ok $after_count, '==', 4;

        $before_count = 0;
        $after_count = 0;

        note "Trying a nonexistent address\n";
        $browser->timing('1,2,3');
        is($browser->timing, '1,2,3');
        $resp = $browser->request( GET "http://localhost:$port/notfound" );
        ok !$resp->is_success;
        note "That gave: ", $resp->status_line, "\n";
        note "Before_count: $before_count\n";
        cmp_ok $before_count, '==', 1;
        note "After_count: $after_count\n";
        cmp_ok $after_count, '==', 1;
    },
);
