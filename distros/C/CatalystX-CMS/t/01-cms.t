#!/usr/bin/perl

use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );

use Test::More tests => 10;
use lib 't/MyCMS/lib';

use Catalyst::Test 'MyCMS';
use HTTP::Request::Common;

my $result;

# create a page
ok( $result = request('/cms/mypage?cxcms=create'), "GET create" );

#diag( dump $result );

is( $result->code, 400, "may not GET to create" );

ok( $result = request( POST('/cms/mypage?cxcms=create') ), "POST create" );

#diag( dump $result );

is( $result->code, 302, "redirect on create" );

# fetch new URI and check content

ok( $result = request('/cms/mypage'), "get redirect uri" );

#diag( dump $result );

is( $result->code, 200, "GET new page ok" );

# save some new content

ok( $result = request(
        POST(
            '/cms/mypage?cxcms=save',
            [   'x-tunneled-method' => 'PUT',
                'text'              => 'cxcms test mypage'
            ]
        )
    ),
    "POST new text content"
);

#diag( dump $result );

is( $result->code, 302, "redirect on save" );

#diag( $result->code );

ok( $result = request( $result->header('location') ),
    "GET updated content" );

#diag( dump $result );

like( $result->content, qr/cxcms test mypage/, "content matches" );

1;

__END__

=head1 ABOUT

This module is part of the Minnesota Supercomputing Institute Perl library.
See http://www.msi.umn.edu/

=head1 LICENSE

Copyright 2009 by the Regents of the University of Minnesota.

=cut
