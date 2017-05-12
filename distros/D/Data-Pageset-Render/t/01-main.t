#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 14;
use Data::Pageset::Render;

## Simple test with just format strings

#fixed mode
my $pager = Data::Pageset::Render->new( {
        total_entries    => 100,
        entries_per_page => 10,
        current_page     => 1,
        mode             => 'fixed',
        ## pages_per_set    => 5,
        link_format => '%a ',
} );
isa_ok $pager, 'Data::Pageset::Render';
like $pager->html(), '1 2 3 4 5 6 7 8 9 10 &gt;&gt;', 'simple: no sets';
$pager->pages_per_set(5);
like $pager->html(), '1 2 3 4 5 ... 10 &gt;&gt;', 'pages per set = 5';
$pager->current_page(10);
like $pager->html(), '&lt;&lt; 1 ... 6 7 8 9 10', 'pps=5, cur=10';
$pager->current_page(5);
like $pager->html(), '&lt;&lt; 1 2 3 4 5 ... 10 &gt;&gt;', 'pps=5, cur=5';

#slide mode
$pager = Data::Pageset::Render->new( {
        total_entries    => 100,
        entries_per_page => 10,
        current_page     => 1,
        mode             => 'slide',
        ## pages_per_set    => 5,
        link_format => '%a ',
} );
isa_ok $pager, 'Data::Pageset::Render';
like $pager->html(), '1 2 3 4 5 6 7 8 9 10 &gt;&gt;', 'simple slide: no sets';
$pager->pages_per_set(5);
like $pager->html(), '1 2 3 4 5 ... 10 &gt;&gt;', 'pages per set = 5';
$pager->current_page(10);
like $pager->html(), '&lt;&lt; 1 ... 6 7 8 9 10', 'pps=5, cur=10';
$pager->current_page(5);
like $pager->html(), '&lt;&lt; 1 ... 3 4 5 6 7 ... 10 &gt;&gt;',
  'pps=5, cur=5, slide';

# A bit more complicated, use both %p and %a
$pager->current_page(1);
like $pager->html('<a href="i?p=%p">%a</a>'), q{ 1
        <a href="i?p=2">2</a>
        <a href="i?p=3">3</a>
        <a href="i?p=4">4</a>
        <a href="i?p=5">5</a>
        <a href="i?p=8">...</a>
        <a href="i?p=10">10</a>
        <a href="i?p=2">&gt;&gt;</a>
      }, 'format string, current page = 1';

$pager->current_page(6);
like $pager->html('<a href="i?p=%p">%a</a>'), q{ <a href="i?p=5">&lt;&lt;</a>
        <a href="i?p=1">1</a>
        <a href="i?p=1">...</a>
        <a href="i?p=4">4</a>
        <a href="i?p=5">5</a>
        6
        <a href="i?p=7">7</a>
        <a href="i?p=8">8</a>
        <a href="i?p=11">...</a>
        <a href="i?p=10">10</a>
        <a href="i?p=7">&gt;&gt;</a>
      }, 'format string, current page = 6';

like $pager->html('<a href="i?p=%p">[%a]</a>'),
  q{ <a href="i?p=5">[&lt;&lt;]</a>
        <a href="i?p=1">[1]</a>
        <a href="i?p=1">[...]</a>
        <a href="i?p=4">[4]</a>
        <a href="i?p=5">[5]</a>
        6
        <a href="i?p=7">[7]</a>
        <a href="i?p=8">[8]</a>
        <a href="i?p=11">[...]</a>
        <a href="i?p=10">[10]</a>
        <a href="i?p=7">[&gt;&gt;]</a>
      }, 'format string with [x]';

like $pager->html( '<a href="i?p=%p">%a</a>', '[%a=%p]' ),
  q{ <a href="i?p=5">&lt;&lt;</a>
        <a href="i?p=1">1</a>
        <a href="i?p=1">...</a>
        <a href="i?p=4">4</a>
        <a href="i?p=5">5</a>
        [6=6]
        <a href="i?p=7">7</a>
        <a href="i?p=8">8</a>
        <a href="i?p=11">...</a>
        <a href="i?p=10">10</a>
        <a href="i?p=7">&gt;&gt;</a>
      }, 'format string for both linked pages and current page';

no warnings 'redefine';

sub like($$;$) {
    my ( $result, $expected, $desc ) = @_;

    $expected =~ s/^\s*//gm;
    $expected =~ s/\n/\\s*\n/g;
    $expected =~ s/[\t ]+/\\s+/g;
    $expected =~ s/([\.\?\[\]])/\\$1/g;
    return Test::More::like( $result, qr/^\s*$expected\s*$/x, $desc );
}
