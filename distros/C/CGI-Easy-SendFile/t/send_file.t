use warnings;
use strict;
use Test::More;
use CGI::Easy::Headers;
use CGI::Easy::Util qw( date_http );

use CGI::Easy::SendFile qw( send_file );

plan tests=>50;


my $r = { ENV => {} };
my $h = CGI::Easy::Headers->new();
my ($data, $wait);
my %wait_h = (
    'Status'                => '200 OK',
    'Date'                  => q{},
    'Set-Cookie'            => [],
    'Accept-Ranges'         => 'bytes',
    'Content-Type'          => 'application/x-download',
);
my $data_dynamic = 'Test file';
my $file_dynamic = \$data_dynamic;
my $data_real    = do { seek DATA, 0, 0; join q{}, <DATA> };
my $file_real    = $0;


# default

$h = CGI::Easy::Headers->new();
$data = send_file($r, $h, $file_dynamic);
is ${$data}, $data_dynamic, 'default dynamic';
is_deeply $h, { %wait_h,
    'Expires'               => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$h = CGI::Easy::Headers->new();
$data = send_file($r, $h, $file_real);
is ${$data}, $data_real, 'default real';
is_deeply $h, { %wait_h,
    'Expires'               => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_real,
};

# cache

$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    type    => 'image/png',
    cache   => 1,
    inline  => 1,
});
is ${$data}, $data_dynamic, 'image/cache/inline dynamic';
is_deeply $h, { %wait_h,
    'Content-Type'          => 'image/png',
    'Content-Length'        => length $data_dynamic,
};

$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_real, {
    type    => 'image/png',
    cache   => 1,
    inline  => 1,
});
is ${$data}, $data_real, 'image/cache/inline real';
is_deeply $h, { %wait_h,
    'Content-Type'          => 'image/png',
    'Content-Length'        => length $data_real,
    'Last-Modified'         => date_http((stat $file_real)[9]),
};

$r->{ENV} = { HTTP_IF_MODIFIED_SINCE => 'Sat, 01 Jan 2000 00:00:00 GMT' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_real, {
    type    => 'image/png',
    cache   => 1,
    inline  => 1,
});
is ${$data}, $data_real, 'image/cache/inline real (ifmod in past)';
is_deeply $h, { %wait_h,
    'Content-Type'          => 'image/png',
    'Content-Length'        => length $data_real,
    'Last-Modified'         => date_http((stat $file_real)[9]),
};

$r->{ENV} = { HTTP_IF_MODIFIED_SINCE => date_http((stat $file_real)[9]) };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_real, {
    type    => 'image/png',
    cache   => 1,
    inline  => 1,
});
is ${$data}, q{}, 'image/cache/inline real (ifmod current)';
is_deeply $h, {
    Status                  => '304 Not Modified',
    'Content-Type'          => 'text/html; charset=utf-8',  # XXX?
    'Set-Cookie'            => [],
    Date                    => q{},
};

$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_real, {
    type    => 'image/png',
    inline  => 1,
});
is ${$data}, $data_real, 'image/inline real (ifmod current)';
is_deeply $h, { %wait_h,
    'Expires'               => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Type'          => 'image/png',
    'Content-Length'        => length $data_real,
};

$r->{ENV} = { HTTP_IF_MODIFIED_SINCE => 'Tue, 01 Jan 2030 00:00:00 GMT' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_real, {
    type    => 'image/png',
    cache   => 1,
    inline  => 1,
});
is ${$data}, $data_real, 'image/cache/inline real (ifmod in future)';
is_deeply $h, { %wait_h,
    'Content-Type'          => 'image/png',
    'Content-Length'        => length $data_real,
    'Last-Modified'         => date_http((stat $file_real)[9]),
};

# range

$r->{ENV} = {};
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range (no HTTP_RANGE)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=0-' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range 0- (full)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=1-' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,1), 'range 1-';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length(substr($data_dynamic,1)),
    'Content-Range'         => 'bytes 1-8/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=8-' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,8), 'range 8-';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length(substr($data_dynamic,8)),
    'Content-Range'         => 'bytes 8-8/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=9-' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range 9- (wrong)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=0-0' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,0,1), 'range 0-0';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => 1,
    'Content-Range'         => 'bytes 0-0/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=0-1' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,0,2), 'range 0-1';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => 2,
    'Content-Range'         => 'bytes 0-1/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=2-4' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,2,3), 'range 2-4';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => 3,
    'Content-Range'         => 'bytes 2-4/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=2-4' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic);
is ${$data}, $data_dynamic, 'range 2-4 (disabled {range})';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=7-8' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,7), 'range 7-8';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => 2,
    'Content-Range'         => 'bytes 7-8/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=7-9' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range 7-9 (wrong)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=0-8' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range 0-8 (full)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=-0' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range -0 (wrong)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=-1' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,-1), 'range -1';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => 1,
    'Content-Range'         => 'bytes 8-8/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=-4' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, substr($data_dynamic,-4), 'range -4';
is_deeply $h, { %wait_h,
    Status                  => '206 Partial Content',
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => 4,
    'Content-Range'         => 'bytes 5-8/9',
};

$r->{ENV} = { HTTP_RANGE => 'bytes=-9' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range -9 (full)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};

$r->{ENV} = { HTTP_RANGE => 'bytes=-10' };
$h = CGI::Easy::Headers->new();
$h->{Expires} = 'Sat, 01 Jan 2000 00:00:00 GMT',
$data = send_file($r, $h, $file_dynamic, {
    range   => 1,
});
is ${$data}, $data_dynamic, 'range -10 (wrong)';
is_deeply $h, { %wait_h,
    Expires                 => 'Sat, 01 Jan 2000 00:00:00 GMT',
    'Content-Disposition'   => 'attachment',
    'Content-Length'        => length $data_dynamic,
};








__DATA__
