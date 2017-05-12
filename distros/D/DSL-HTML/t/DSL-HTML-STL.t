use strict;
use warnings;

use HTML::TreeBuilder;

use Fennec::Declare class => 'DSL::HTML::STL';

use DSL::HTML;
BEGIN { use_ok $CLASS }

describe test {
    my $WANT = <<'    EOT';
<html>
    <head>
    </head>
    <body>
        <ul class="">
            <li>foo</li>
            <li>bar</li>
            <li>baz</li>
        </ul>

        <ol class="">
            <li>foo</li>
            <li>bar</li>
            <li>baz</li>
        </ol>

        <dl class="blue">
            <dt>foo</dt>
            <dd>Foo</dd>
            <dt>bar</dt>
            <dd>Bar</dd>
            <dt>baz</dt>
            <dd>Baz</dd>
        </dl>
    </body>
</html>
    EOT
    
    template test {
        include ul => [qw(foo bar baz)];
        include ol => [qw(foo bar baz)];

        include dl => (
            'blue',
            [qw/bar foo baz/],
            {
                foo => "Foo",
                bar => "Bar",
                baz => "Baz",
                bat => "Should not see me",
            },
            sub($$) {
                my ($a, $b) = @_;
                return -1 if $a eq 'foo';
                return  1 if $b eq 'foo';
                return $a cmp $b;
            }
        );
    }
    
    tests template {
        my $html = build_template 'test';
        my $got_tree  = HTML::TreeBuilder->new;
        my $want_tree = HTML::TreeBuilder->new;
    
        $got_tree->parse_content($html);
        $want_tree->parse_content($WANT);
    
        $got_tree->elementify;
        $want_tree->elementify;

        is_deeply( $got_tree, $want_tree, "Got expected html" );
    }
}

done_testing;
