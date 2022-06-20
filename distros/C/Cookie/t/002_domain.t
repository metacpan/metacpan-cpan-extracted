#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use Test::More;
    use_ok( 'Cookie::Domain' );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
    require "t/env.pl";
};

my $dom = Cookie::Domain->new( debug => $DEBUG );
isa_ok( $dom, 'Cookie::Domain' );

# To generate this list:
# egrep -E '^sub ' ./lib/Cookies/Domain.pm | perl -lnE 'my $m = [split(/\s+/, $_)]->[1]; say "can_ok( \$dom, \"$m\" );"'
can_ok( $dom, "init" );
can_ok( $dom, "cron_fetch" );
can_ok( $dom, "decode" );
can_ok( $dom, "encode" );
can_ok( $dom, "file" );
can_ok( $dom, "json_file" );
can_ok( $dom, "load" );
can_ok( $dom, "load_json" );
can_ok( $dom, "load_public_suffix" );
can_ok( $dom, "meta" );
can_ok( $dom, "min_suffix" );
can_ok( $dom, "save_as_json" );
can_ok( $dom, "stat" );
can_ok( $dom, "suffixes" );

use utf8;
my @tests = (
    [ 'com' => { suffix => 'com' }, { add => 1, min_suffix => 1 } ],
    [ 'bar.com' => { suffix => 'bar.com' }, { add => 1, min_suffix => 1 } ],
    [ 'www.bar.com' => { name => 'www', suffix => 'bar.com' }, { add => 1, min_suffix => 1 } ],
    [ 'www.foo.bar.com' => { sub => 'www', name => 'foo', suffix => 'bar.com' }, { add => 1, min_suffix => 1 } ],
    [ 'uk' => { suffix => 'uk' }, { add => 1, min_suffix => 1 } ],
    [ 'co.uk' => { suffix => 'co.uk' }, { add => 1, min_suffix => 1 } ],
    [ 'www.co.uk' => { suffix => 'www.co.uk' }, { add => 1, min_suffix => 1 } ],
    [ 'www.bar.co.uk' => { name => 'www', suffix => 'bar.co.uk' }, { add => 1, min_suffix => 1 } ],
    [ 'www.foo.bar.co.uk' => { sub => 'www', name => 'foo', suffix => 'bar.co.uk' }, { add => 1, min_suffix => 1 } ],
    [ 'bl.uk' => { suffix => 'bl.uk' }, { add => 1, min_suffix => 1 } ],
    [ 'www.bl.uk' => { name => 'www',suffix => 'bl.uk' }, { add => 1, min_suffix => 1 } ],
    [ 'www.bar.bl.uk' => { sub => 'www', name => 'bar', suffix => 'bl.uk' }, { add => 1, min_suffix => 1 } ],
    [ 'www.foo.bar.bl.uk' => { sub => 'www.foo', name => 'bar', suffix => 'bl.uk' }, { add => 1, min_suffix => 1 } ],
    [ undef() => undef() ],
    [ '' => undef() ],

    [ 'COM' => { suffix => 'com' } ],
    [ 'example.COM' => { name => 'example', suffix => 'com' } ],
    [ 'WwW.example.COM' => { sub => 'www', name => 'example', suffix => 'com' } ],
    [ '123bar.com' => { name => '123bar', suffix => 'com' } ],
    [ 'foo.123bar.com' => { sub => 'foo', name => '123bar', suffix => 'com' } ],
    
    # Leading dot:
    [ '.com' => { suffix => 'com' } ],
    [ '.example' => '' ],
    [ '.example.com' => { name => 'example', suffix => 'com' } ],
    [ '.example.example' => '' ],

    # Unlisted TLD:
    [ 'example' => '' ],
    [ 'example.example' => '' ],
    [ 'b.example.example' => '' ],
    [ 'a.b.example.example' => '' ],

    # Listed, but non-Internet, TLD:
    [ 'local' => '' ],
    [ 'example.local' => '' ],
    [ 'b.example.local' => '' ],
    [ 'a.b.example.local' => '' ],

    # TLD with only one rule:
    [ 'biz' => { suffix => 'biz' } ],
    [ 'domain.biz' => { name => 'domain', suffix => 'biz' } ],
    [ 'b.domain.biz' => { sub => 'b', name => 'domain', suffix => 'biz' } ],
    [ 'a.b.domain.biz' => { sub => 'a.b', name => 'domain', suffix => 'biz' } ],

    # TLD with some two-level rules:
    [ 'com' => { suffix => 'com' } ],
    [ 'example.com' => { name => 'example', suffix => 'com' } ],
    [ 'b.example.com' => { sub => 'b', name => 'example', suffix => 'com' } ],
    [ 'a.b.example.com' => { sub => 'a.b', name => 'example', suffix => 'com' } ],

    [ 'test.ac' => { name => 'test', suffix => 'ac' } ],

    [ 'bd' => { suffix => 'bd' } ],

    [ 'c.bd' => { suffix => 'c.bd' } ],
    [ 'b.c.bd' => { name => 'b', suffix => 'c.bd' } ],
    [ 'a.b.c.bd' => { sub => 'a', name => 'b', suffix => 'c.bd' } ],

    # More complex suffixes:
    [ 'jp' => { suffix => 'jp' } ],
    [ 'test.jp' => { name => 'test', suffix => 'jp' } ],
    [ 'www.test.jp' => { sub => 'www', name => 'test', suffix => 'jp' } ],
    [ 'ac.jp' => { suffix => 'ac.jp' } ],
    [ 'test.ac.jp' => { name => 'test', suffix => 'ac.jp' } ],
    [ 'www.test.ac.jp' => { sub => 'www', name => 'test', suffix => 'ac.jp' } ],
    [ 'kyoto.jp' => { suffix => 'kyoto.jp' } ],
    [ 'c.kyoto.jp' => { name => 'c', suffix => 'kyoto.jp' } ],
    [ 'b.c.kyoto.jp' => { sub => 'b', name => 'c', suffix => 'kyoto.jp' } ],
    [ 'a.b.c.kyoto.jp' => { sub => 'a.b', name => 'c', suffix => 'kyoto.jp' } ],
    [ 'ayabe.kyoto.jp' => { suffix => 'ayabe.kyoto.jp' } ],
    [ 'test.kobe.jp' => { suffix => 'test.kobe.jp' } ],     # Wildcard rule.
    [ 'www.test.kobe.jp' => { name => 'www', suffix => 'test.kobe.jp' } ], # Wildcard rule.
    [ 'city.kobe.jp' => { name => 'city', suffix => 'kobe.jp' } ],          # Exception rule.
    [ 'www.city.kobe.jp' => { sub => 'www', name => 'city', suffix => 'kobe.jp' } ],      # Identity rule.

    [ 'ck' => { suffix => 'ck' } ],

    [ 'test.ck' => { suffix => 'test.ck' } ],
    [ 'b.test.ck' => { name => 'b', suffix => 'test.ck' } ],
    [ 'a.b.test.ck' => { sub => 'a', name => 'b', suffix => 'test.ck' } ],
    [ 'www.ck' => { name => 'www', suffix => 'ck' } ],
    [ 'www.www.ck' => { sub => 'www', name => 'www', suffix => 'ck' } ],

    # US K12:
    [ 'us' => { suffix => 'us' } ],
    [ 'test.us' => { name => 'test', suffix => 'us' } ],
    [ 'www.test.us' => { sub => 'www', name => 'test', suffix => 'us' } ],
    [ 'ak.us' => { suffix => 'ak.us' } ],
    [ 'test.ak.us' => { name => 'test', suffix => 'ak.us' } ],
    [ 'www.test.ak.us' => { sub => 'www', name => 'test', suffix => 'ak.us' } ],
    [ 'k12.ak.us' => { suffix => 'k12.ak.us' } ],
    [ 'test.k12.ak.us' => { name => 'test', suffix => 'k12.ak.us' } ],
    [ 'www.test.k12.ak.us' => { sub => 'www', name => 'test', suffix => 'k12.ak.us' } ],

    [ 'test.東京.jp' => { name => 'test', suffix => '東京.jp' } ],
    [ '中文.tw' => { name => '中文', suffix => 'tw' } ],
    [ 'ਭਾਰਤ.ਭਾਰਤ' => { name => 'ਭਾਰਤ', suffix => 'ਭਾਰਤ' } ],
    
    [ '食狮.com.cn' => { name => '食狮', suffix => 'com.cn' } ],
    [ '食狮.公司.cn' => { name => '食狮', suffix => '公司.cn' } ],
    [ 'www.食狮.公司.cn' => { sub => 'www', name => '食狮', suffix => '公司.cn' } ],
    [ 'shishi.公司.cn' => { name => 'shishi', suffix => '公司.cn' } ],
    [ '公司.cn' => { suffix => '公司.cn' } ],
    [ '食狮.中国' => { name => '食狮', suffix => '中国' } ],
    [ 'www.食狮.中国' => { sub => 'www', name => '食狮', suffix => '中国' } ],
    [ 'shishi.中国' => { name => 'shishi', suffix => '中国' } ],
    [ '中国' => { suffix => '中国' } ],
);

SKIP:
{
    if( !defined( $dom ) )
    {
        diag( "Failed to instantiate a Cookie::Domain object: ", Cookie::Domain->error ) if( $DEBUG );
        skip( "Failed to instantiate a Cookie::Domain object.", ( scalar( @tests ) * 5 ) );
    }
    
    no warnings 'uninitialized';
    foreach my $test ( @tests )
    {
        my $res = scalar( @$test ) > 2 ? $dom->stat( $test->[0], $test->[2] ) : $dom->stat( $test->[0] );
        my $expect = $test->[1];
        # is( ref( $res ), ref( $expect ), 'result type for ' . $test->[0] );
        if( ref( $expect ) )
        {
            isa_ok( $res, 'Cookie::Domain::Result', 'result type for ' . $test->[0] );
            my $all_ok = 1;
            foreach my $k ( qw( name sub suffix ) )
            {
                if( ( defined( $res->{ $k } ) && !exists( $expect->{ $k } ) ) ||
                    $expect->{ $k } ne $res->{ $k } )
                {
                    diag( "\tCould not find property '$k' or our expected value '", $expect->{ $k }, "' does not match what we received '", $res->{ $k }, "'" );
                    $all_ok = 0;
                    last;
                }
                my $v = $res->$k();
                # is( $v, $expect->{ $k }, "\$res->$k() for " . $test->[0] . " (" . ( defined( $v ) ? $v->length : 0 ) . ")" );
                is( $v, $expect->{ $k }, "\$res->$k() for " . $test->[0] );
            }
            ok( $all_ok, 'result hash for ' . $test->[0] );
        }
        else
        {
            is( $res, $expect, 'result type for ' . $test->[0] );
            is( $res, $expect, 'result for ' . $test->[0] );
        }
    }
};

done_testing();

__END__

