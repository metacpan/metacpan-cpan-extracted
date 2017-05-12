use strict;
use warnings;

use HTML::TreeBuilder;

use Fennec::Declare class => 'DSL::HTML';

BEGIN { use_ok $CLASS, '-default', '!import' }

my $WANT = <<EOT;
<html>
    <head>
        <title>foo</title>
        <meta foo="bar" />
        <link href="a.css" rel="stylesheet" type="text/css" />
        <link href="b.css" rel="stylesheet" type="text/css" />
    </head>
    <body>
        <div>test</div>
        <div>nested body</div>
        <div class="a c e" id="bar" style="display: none;">
        </div>
        <div foo="bar" id="go_away">
        </div>simple text<div>test</div>
        <div>nested body</div>
        <div class="a c e" id="bar" style="display: none;">
        </div>
        <div foo="bar" id="go_away">
        </div>simple text</body>
    <script src="a.js"></script>
    <script src="b.js"></script>
</html>
EOT

describe exports {
    return unless $self->can_ok( qw{
        template
        tag
        text
        css
        js
        attr
        add_class
        del_class
        build_template
        get_template
        include
    });

    template test {
        isa_ok( $tag, 'HTML::Element' );
        like( $tag->tag, qr/^(body|TEMP)$/i, "In the root tag" );
        my $count = shift;

        tag div { 'test' }
        css 'a.css';
        css 'b.css';
        css 'b.css'; # duplicate

        if ( $count ) {
            tag head {
                is( $tag->tag, 'head', "Got head tag" );
                tag title { 'foo' }
            }
        }

        # Ensure that there is only ever 1 head tag
        unless ( $count ) {
            tag head {
                tag meta(foo => 'bar') {}
            }
        }

        # Not necessary, body is already top of the stack
        tag body {
            is( $tag->tag, 'body', "Got body tag" );
            tag div { 'nested body' }

            # Despite the nesting these still go to the head
            js 'a.js';
            js 'b.js';
            js 'b.js'; #duplicate
        }

        tag div(id => 'bar', class => 'a b c' ) {
            is( $tag->tag, 'div', "Inside div" );
            add_class 'e';
            del_class 'b';
            attr style => 'display: none;';
        }

        tag div(id => 'go_away') {
            attr { foo => 'bar' };
        }

        text "simple text";

        # Nested template call
        include test => $count - 1 if $count;
    }

    tests access {
        ok( $self->get_template( 'test' ), "got the template via method" );
        ok( get_template( 'test' ), "got the template via function" );
    }

    tests template {
        my $html = build_template test => 1;
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
