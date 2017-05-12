#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $testdata = [
    {
        create_args     => [],
        pages_in_set    => [1 .. 5],
        show            => qq(1&nbsp;
<a href="?page=2">2</a>&nbsp;
<a href="?page=3">3</a>&nbsp;
<a href="?page=4">4</a>&nbsp;
<a href="?page=5">5</a>&nbsp;
<a href="?page=2">&gt;Next</a>&nbsp;
<a href="?page=10">&gt;&gt;Last</a>),
    },
    {
        create_args     => [
            curitem => 4
        ],
        pages_in_set    => [2 .. 6],
        show            => qq(<a href="?page=1">&lt;&lt;First</a>&nbsp;
<a href="?page=3">&lt;Previous</a>&nbsp;
<a href="?page=2">2</a>&nbsp;
<a href="?page=3">3</a>&nbsp;
4&nbsp;
<a href="?page=5">5</a>&nbsp;
<a href="?page=6">6</a>&nbsp;
<a href="?page=5">&gt;Next</a>&nbsp;
<a href="?page=10">&gt;&gt;Last</a>),
    },
    {
        create_args     => [
            curitem => 15,
        ],
        pages_in_set    => [6 .. 10],
        show            => qq(<a href="?page=1">&lt;&lt;First</a>&nbsp;
<a href="?page=9">&lt;Previous</a>&nbsp;
<a href="?page=6">6</a>&nbsp;
<a href="?page=7">7</a>&nbsp;
<a href="?page=8">8</a>&nbsp;
<a href="?page=9">9</a>&nbsp;
10),
    },
];

plan tests => 2 + ( @$testdata * 3 );

#BEGIN begin block doesn't work when planning tests runtime
{
    use_ok( 'Data::Page' );
    use_ok( 'Data::Page::Set' );
}

sub create_page_set {
    my %attr = @_;
    my $datalen = $attr{datalen} || 150;
    my $curitem = $attr{curitem} || 1;
    my $itemspp = $attr{itemspp} || 15;
    my $setsize = $attr{setsize} || 5;
    my $show    = $attr{show}    || {};

    my @data = 0 .. $datalen - 1;
    my $page = Data::Page->new(
        scalar @data,
        $itemspp,
        $curitem,
    );
    my $pageset = Data::Page::Set->new(
        $page,
        $setsize,
        $show,
    );

    return wantarray ? ($pageset, \@data)
                     : $pageset;
}



for my $test ( @$testdata ) {
    my $pageset = create_page_set( @{$test->{create_args}} );
    isa_ok( $pageset, 'Data::Page::Set' );
    is_deeply(
        [$pageset->pages_in_set],
        $test->{pages_in_set},
        "pages_in_set ok",
    );

    is(
        $pageset->show,
        $test->{show},
        "show ok",
    );
}






