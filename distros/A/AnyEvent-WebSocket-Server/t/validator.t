use strict;
use warnings;
use Test::More;
use FindBin;
use lib ($FindBin::RealBin);
use testlib::Util qw(start_server set_timeout);
use testlib::ConnConfig;
use AnyEvent::WebSocket::Client;
use AnyEvent::WebSocket::Server;
use Try::Tiny;

set_timeout;

my $USER_ID_MIN = 1;
my $USER_ID_MAX = 100;

testlib::ConnConfig->for_all_ok_conn_configs(sub {
    my ($cconfig) = @_;

    my $server = AnyEvent::WebSocket::Server->new(
        $cconfig->server_args,
        validator => sub {
            my ($req) = @_;
            my $path = $req->resource_name;
            die "invalid format" if $path !~ m{^/user/(\d+)};
            my $user_id = $1;
            die "invalid user ID" if $user_id < $USER_ID_MIN || $user_id > $USER_ID_MAX;
            return ($user_id, "HOGE");
        }
    );

    my @results = ();

    my $cv_port = start_server sub {
        my $fh = shift;
        $server->establish($fh)->cb(sub {
            my $cv = shift;
            try {
                my ($conn, $user_id, $hoge) = $cv->recv;
                push(@results, { id => $user_id, hoge => $hoge });
            }catch {
                my $e = shift;
                push(@results, { error => $e });
            };
        });
    };
    my $port = $cv_port->recv;
    note("port $port opened.");

    my $client = AnyEvent::WebSocket::Client->new($cconfig->client_args);

    foreach my $case (
        {label => "valid ID", path => '/user/10', exp => {id => 10, hoge => "HOGE"}},
        {label => "invalid ID", path => '/user/102', exp => {error => qr/^invalid user ID/}},
        {label => "invalid path format", path => '/2013/10/19', exp => {error => qr/^invalid format/}},
    ) {
        subtest $case->{label}, sub {
            my $cv_close = AnyEvent->condvar;
            @results = ();
            try {
                my $conn = $client->connect($cconfig->connect_url($port, $case->{path}))->recv;
                note("connection OK");
                $conn->on(finish => sub { undef $conn; $cv_close->send });
                $conn->close;
            }catch {
                note("connection error");
                $cv_close->send;
            };
            $cv_close->recv;
            note("connection finish");
            is(scalar(@results), 1, "$case->{label}: there should be only one connection");
            if($case->{exp}{error}) {
                like($results[0]{error}, $case->{exp}{error}, "$case->{label}: connection error OK");
            }else {
                is_deeply(\@results, [$case->{exp}], "$case->{label}: connection success OK");
            }
        };
    }
});

done_testing();
