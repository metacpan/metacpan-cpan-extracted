#!/usr/bin/env perl
BEGIN
{
    use strict;
    use warnings FATAL => 'all';
    use Test::More;
    use_ok( 'Apache2::SSI::Common' );
};

{
    # Based on RFC 3986 sectin 5.2.4 algorithm, flattening the dots such as '.' and '..' in uri path
    my $tests =
    [
        '/'                                                         => '/',
        '/../a/b/../c/./d.html'                                     => '/a/c/d.html',
        '/../a/b/../c/./d.html?foo=../bar'                          => '/a/c/d.html?foo=../bar',
        '/foo/../bar'                                               => '/bar',
        '/foo/../bar/'                                              => '/bar/',
        '/../foo'                                                   => '/foo',
        '/../foo/..'                                                => '/',
        '/../../'                                                   => '/',
        '/../../foo'                                                => '/foo',
        '/some.cgi/path/info/http://www.example.org/tag/john+doe'   => '/some.cgi/path/info/http://www.example.org/tag/john+doe',
        '/a/b/../../index.html'                                     => '/index.html',
        '/a/../b'                                                   => '/b',
        '/a/.../b'                                                  => '/a/.../b',
        './a//b'                                                    => '/a//b',
        '/path/page/#anchor'                                        => '/path/page/#anchor',
        '/path/page/../#anchor'                                     => '/path/#anchor',
        '/path/page/#anchor/page'                                   => '/path/page/#anchor/page',
        '/path/page/../#anchor/page'                                => '/path/#anchor/page',
    ];
    
    my $ssi = Apache2::SSI::Common->new( debug => 3 );
    isa_ok( $ssi, 'Apache2::SSI::Common', 'instantiating object' );
    for( my $i = 0; $i < scalar( @$tests ); $i += 2 )
    {
        my $test = $tests->[$i];
        my $check = $tests->[$i + 1];
        my $res = $ssi->collapse_dots( $test );
        ok( $res eq $check, "$test => $check" . ( $res ne $check ? " [failed with $res]" : '' ) );
    }
}

done_testing;
