#!perl -T
use strict;
use warnings;
use File::Spec;

use lib File::Spec->catdir('t', 'lib');

ThisTest->runtests;

# ThisTest
package ThisTest;
use base qw/Test::Class/;
use Test::More;
use DBIx::MoCo::Column;
use Blog::Entry;
use MySQLUser;

sub use_test : Tests {
    use_ok 'DBIx::MoCo::Column';
}

sub new_test : Tests {
    my $str = 'hello test';
    my $col = DBIx::MoCo::Column->new($str);
    ok $col;
    isa_ok $col, 'DBIx::MoCo::Column';
    is $$col, $str;
}

sub column : Tests {
    my $e = Blog::Entry->retrieve(1);
    ok $e;
    my $uri = $e->column('uri');
    ok $uri;
    isa_ok $uri, 'DBIx::MoCo::Column';
    is $$uri, $e->uri;
}

sub uri : Tests {
    my $e = Blog::Entry->retrieve(1);
    ok $e;
    my $uri = $e->uri_as_URI;
    ok $uri;
    isa_ok $uri, 'URI';
    is $uri->host, 'test.com';
    my $uri2 = URI->new('http://www.test.com/uri2');
    $e->uri_as_URI($uri2);
    ok ($e->uri, 'uri2');
    is ($e->uri, $uri2->as_string, 'uri2 as string');
    my $uri3 = $e->uri_as_URI;
    ok ($uri3, 'uri3');
    isa_ok ($uri3, 'URI', 'uri3 isa URI');
    is ($uri3->as_string, $uri2->as_string, 'uri2 eq uri3');
}

sub utc_datetime : Tests {
    my $e = Blog::Entry->retrieve(1);
    ok ($e->created, 'has created');
    is ($e->created, '2007-03-04 12:34:56', 'created');
    my $dt = $e->created_as_UTCDateTime;
    ok ($dt, 'has UTCDateTime');
    my $tz = $dt->time_zone;
    ok ($tz, 'has time zone');
    isa_ok ($tz, 'DateTime::TimeZone');
    is ($tz->name, 'UTC', 'tz is UTC');
    is ($dt->ymd . ' ' . $dt->hms, '2007-03-04 12:34:56', 'utc');
    $dt->set_time_zone('Asia/Tokyo');
    is ($dt->ymd . ' ' . $dt->hms, '2007-03-04 21:34:56', 'asia/tokyo');
    my $dt2 = $dt->clone;
    $dt2->add(days => 1);
    $e->created_as_UTCDateTime($dt2);
    is ($e->created, '2007-03-05 12:34:56', 'created');
    $e->created_as_UTCDateTime($dt);

    $e = Blog::Entry->create(uri => 'http://www.example.com/');
    is ($e->created, undef, 'undefined column');
    is ($e->created_as_UTCDateTime, undef, 'inflates undefined column');
}

sub datetime : Tests {
    my $e = Blog::Entry->retrieve(1);
    ok ($e->created, 'has created');
    is ($e->created, '2007-03-04 12:34:56', 'created');
    my $dt = $e->created_as_DateTime;
    ok ($dt, 'has UTCDateTime');
    my $tz = $dt->time_zone;
    ok ($tz, 'has time zone');
    isa_ok ($tz, 'DateTime::TimeZone');
    is ($tz->name, 'floating', 'tz is floating');
    is ($dt->ymd . ' ' . $dt->hms, '2007-03-04 12:34:56', 'floating');
    $dt->set_time_zone('Asia/Tokyo');
    is ($dt->ymd . ' ' . $dt->hms, '2007-03-04 12:34:56', 'asia/tokyo');
    my $dt2 = $dt->clone;
    $dt2->add(days => 1);
    $e->created_as_DateTime($dt2);
    is ($e->created, '2007-03-05 12:34:56', 'created');
    $e->created_as_DateTime($dt);

    $e = Blog::Entry->create(uri => 'http://www.example.com/');
    is ($e->created, undef, 'undefined column');
    is ($e->created_as_DateTime, undef, 'inflates undefined column');
}

sub my_column : Tests {
    my $e = Blog::Entry->retrieve(1);
    ok $e;
    my $title = $e->title;
    ok $title;
    is $e->title_as_MyColumn, 'My Column ' . $title;
}

sub has_column : Tests {
    MySQLDB->dbh or return('skipped mysql tests');
    ok (MySQLUser->has_column('User'));
    ok (!MySQLUser->has_column('fake'));
    my $u = MySQLUser->search(where => '1 = 1')->first;
    $u or return;
    ok $u;
    ok ($u->has_column('User'), 'User');
    ok (!$u->has_column('fake'), 'fake');
}

1;
