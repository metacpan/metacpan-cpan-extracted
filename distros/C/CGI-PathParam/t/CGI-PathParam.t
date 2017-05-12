#!/usr/bin/env perl
#
# $Revision: 1.3 $
# $Source: /home/cvs/CGI-PathParam/t/CGI-PathParam.t,v $
# $Date: 2006/06/01 06:23:24 $
#
use strict;
use warnings;
our $VERSION = '0.03';

use blib;
use Test::More tests => 17;

use CGI;
use CGI::PathParam;

my $cgi = CGI->new;

can_ok( $cgi, qw(path_param) );

$cgi->path_info(undef);
is( $cgi->path_info, q{}, 'checking path_info behavior' );

# getter tests
$cgi->path_info(q{});
is_deeply( [ $cgi->path_param ], [], 'no argument(path_info is empty)' );

$cgi->path_info(q{/});
is_deeply( [ $cgi->path_param ], [], 'no argument(path_info is / only)' );

$cgi->path_info('/foo');
is_deeply( [ $cgi->path_param ], ['foo'], 'one argument' );

$cgi->path_info('/foo/bar');
is_deeply( [ $cgi->path_param ], [ 'foo', 'bar' ], 'some arguments' );

$cgi->path_info('/foo%2Fbar');
is_deeply( [ $cgi->path_param ],
    ['foo/bar'], 'contains %2F(slash which is percent encoded)' );

$cgi->path_info('/foo%2Fbar%2Fbaz');
is_deeply( [ $cgi->path_param ], ['foo/bar/baz'], 'contains some %2F' );

$cgi->path_info('/foo/bar%2Fbaz');
is_deeply( [ $cgi->path_param ], [ 'foo', 'bar/baz' ], 'mix of / and %2F' );

# setter tests
$cgi->path_param(undef);    # This causes warnings 'uninitialized'.
is( $cgi->path_info, q{}, 'set an undef' );

$cgi->path_param(q{});
is( $cgi->path_info, q{}, 'set an empty string' );

$cgi->path_param(q{/});
is( $cgi->path_info, '/%2F', 'set a slash' );

$cgi->path_param('foo');
is( $cgi->path_info, '/foo', 'set an argument' );

$cgi->path_param( 'foo', 'bar' );
is( $cgi->path_info, '/foo/bar', 'set some arguments' );

$cgi->path_param('foo/bar');
is( $cgi->path_info, '/foo%2Fbar', 'escape a slash' );

$cgi->path_param('/foo');
is( $cgi->path_info, '/%2Ffoo', 'even if leading slash' );

$cgi->path_param( 'foo', '/bar/baz' );
is( $cgi->path_info, '/foo/%2Fbar%2Fbaz',
    'some arguments contains some slash' );
