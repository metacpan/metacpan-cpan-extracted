#!/usr/bin/env perl
use strict;
use warnings;
use Fennec::Declare class => 'DSL::HTML';

BEGIN {
    use_ok( $CLASS );
}

template foo {
    my ($name) = @_;

    js 'some/other/js/file.js';

    tag div(class => 'external') {
        "A '$name' is had";
    }
}

template simple {
    my ($name, @inner) = @_;
    css 'some/css/file.css';
    js  'some/js/file.js';

    tag head {
        tag title { $name }
    }

    tag h1 { "Hey there!" }

    tag p(class => 'divider') {}

    tag div(class => 'something') {
        tag h2 { "inner!" }
        include foo => @inner;
    }
}

my $html;
lives_ok { $html = build_template simple => ( 'foo', 'bar' ) } "Did not die";

like( $html, qr/A \S+bar\S+ is had/, "Got nested text" );

{
    package Test::Consumer;

    use Test::More;
    use Test::Exception;
    main->import();

    can_ok( __PACKAGE__, 'DSL_HTML', 'build_template' );

    my $html2;
    lives_ok { $html2 = build_template( simple => ( 'foo', 'bar' ))}
        "Can build template in the consumer";

    is( $html2, $html, "Identical results" );
}

done_testing;
