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
use Blog::Entry;
use Encode;

sub regist : Test(startup) {
    Blog::Entry->utf8_columns([qw(title body)]);
}

sub utf8_columns : Tests {
    my $utf8 = Blog::Entry->utf8_columns;
    ok ($utf8, 'utf8 columns');
    isa_ok ($utf8, 'ARRAY', 'is array');
}

sub is_utf8_column : Tests {
    ok (Blog::Entry->is_utf8_column('title'), 'title is utf8');
    ok (Blog::Entry->is_utf8_column('body'), 'body is utf8');
    ok (!Blog::Entry->is_utf8_column('uri'), 'uri is not utf8');
}

sub as_utf8 : Tests {
    my $e = Blog::Entry->create(
        uri   => 'http://test/',
        title => 'こんにちは',
        body  => '世界',
    );
    ok ($e, 'entry');
    my $t_u = $e->title_as_utf8;
    ok ($t_u, 'title as utf8');
    ok (Encode::is_utf8($t_u), 'title is utf8');
    ok (Encode::is_utf8($e->body_as_utf8), 'body_as_utf8');
    ok (Encode::is_utf8($e->title), 'title is utf8');
    ok (Encode::is_utf8($e->body), 'body is utf8');
    ok (!Encode::is_utf8($e->uri), 'uri is not utf8');
    ok (!Encode::is_utf8($e->param('title')), 'param title is not utf8');
    ok (!Encode::is_utf8($e->param('body')), 'param body is not utf8');
    ok (!Encode::is_utf8($e->param('uri')), 'param uri is not utf8');
}

1;
