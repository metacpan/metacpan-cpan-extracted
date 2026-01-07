package ChatApp::HTTP;

use strict;
use warnings;
use Future;
use Future::AsyncAwait;
use JSON::MaybeXS;
use File::Spec;
use File::Basename qw(dirname);

use ChatApp::State qw(
    get_all_rooms get_room get_room_messages get_room_users get_stats
);

use Cwd qw(abs_path);

my $JSON = JSON::MaybeXS->new->utf8->canonical;
my $PUBLIC_DIR = abs_path(File::Spec->catdir(dirname(__FILE__), '..', '..', 'public'));

# Debug: print the public dir on load
print STDERR "[HTTP] PUBLIC_DIR = $PUBLIC_DIR\n";

my %MIME_TYPES = (
    html => 'text/html; charset=utf-8',
    css  => 'text/css; charset=utf-8',
    js   => 'application/javascript; charset=utf-8',
    json => 'application/json; charset=utf-8',
    png  => 'image/png',
    ico  => 'image/x-icon',
);

sub handler {
    return async sub {
        my ($scope, $receive, $send) = @_;
        my $path = $scope->{path} // '/';
        my $method = $scope->{method} // 'GET';

        if ($path =~ m{^/api/}) {
            return await _handle_api($scope, $receive, $send, $path, $method);
        }

        return await _serve_static($scope, $receive, $send, $path);
    };
}

async sub _handle_api {
    my ($scope, $receive, $send, $path, $method) = @_;

    my $result = await _do_api($path, $method)->catch(sub {
        my ($err) = @_;
        warn "API error: $err";
        return Future->done({ status => 500, data => { error => 'Internal error' } });
    });

    my $body = $JSON->encode($result->{data});

    await $send->({
        type    => 'http.response.start',
        status  => $result->{status},
        headers => [
            ['content-type', 'application/json; charset=utf-8'],
            ['content-length', length($body)],
        ],
    });

    await $send->({
        type => 'http.response.body',
        body => $body,
    });
}

async sub _do_api {
    my ($path, $method) = @_;

    if ($path eq '/api/rooms' && $method eq 'GET') {
        my $rooms = await get_all_rooms();
        return {
            status => 200,
            data   => [
                map { { name => $_, users => scalar(keys %{$rooms->{$_}{users}}) } }
                sort keys %$rooms
            ],
        };
    }

    if ($path =~ m{^/api/room/([^/]+)/history$} && $method eq 'GET') {
        my $room_name = $1;
        my $room = await get_room($room_name);
        return { status => 404, data => { error => 'Room not found' } } unless $room;
        return { status => 200, data => await get_room_messages($room_name, 100) };
    }

    if ($path =~ m{^/api/room/([^/]+)/users$} && $method eq 'GET') {
        my $room_name = $1;
        my $room = await get_room($room_name);
        return { status => 404, data => { error => 'Room not found' } } unless $room;
        return { status => 200, data => await get_room_users($room_name) };
    }

    if ($path eq '/api/stats' && $method eq 'GET') {
        return { status => 200, data => await get_stats() };
    }

    return { status => 404, data => { error => 'Not found' } };
}

async sub _serve_static {
    my ($scope, $receive, $send, $path) = @_;

    $path = '/index.html' if $path eq '/';
    $path =~ s/\.\.//g;
    $path =~ s|//+|/|g;

    my $file_path = File::Spec->catfile($PUBLIC_DIR, $path);
    print STDERR "[HTTP] Serving: $file_path (exists: " . (-f $file_path ? 'yes' : 'no') . ")\n";

    unless (-f $file_path && -r $file_path) {
        return await _send_404($send);
    }

    my ($ext) = $file_path =~ /\.(\w+)$/;
    my $content_type = $MIME_TYPES{lc($ext // '')} // 'application/octet-stream';

    my $content;
    {
        open my $fh, '<:raw', $file_path or return await _send_500($send);
        local $/;
        $content = <$fh>;
        close $fh;
    }

    await $send->({
        type    => 'http.response.start',
        status  => 200,
        headers => [
            ['content-type', $content_type],
            ['content-length', length($content)],
        ],
    });

    await $send->({
        type => 'http.response.body',
        body => $content,
    });
}

async sub _send_404 {
    my ($send) = @_;
    my $body = '{"error":"Not found"}';
    await $send->({
        type    => 'http.response.start',
        status  => 404,
        headers => [['content-type', 'application/json']],
    });
    await $send->({ type => 'http.response.body', body => $body });
}

async sub _send_500 {
    my ($send) = @_;
    my $body = '{"error":"Internal server error"}';
    await $send->({
        type    => 'http.response.start',
        status  => 500,
        headers => [['content-type', 'application/json']],
    });
    await $send->({ type => 'http.response.body', body => $body });
}

1;
