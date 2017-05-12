use strict;
use warnings;

use Test::More tests => 132;

BEGIN {
    use_ok('CommonMark', ':node', ':event');
}

my $md = <<EOF;
- Item 1
  - *__Text__*
- Item 2
EOF

my $doc = CommonMark->parse_document($md);
isa_ok($doc, 'CommonMark::Node', 'parse_document');

my @expected_events = (
    [ EVENT_ENTER, NODE_DOCUMENT  ],
    [ EVENT_ENTER, NODE_LIST      ],
    [ EVENT_ENTER, NODE_ITEM      ],
    [ EVENT_ENTER, NODE_PARAGRAPH ],
    [ EVENT_ENTER, NODE_TEXT      ],
    [ EVENT_EXIT,  NODE_PARAGRAPH ],
    [ EVENT_ENTER, NODE_LIST      ],
    [ EVENT_ENTER, NODE_ITEM      ],
    [ EVENT_ENTER, NODE_PARAGRAPH ],
    [ EVENT_ENTER, NODE_EMPH      ],
    [ EVENT_ENTER, NODE_STRONG    ],
    [ EVENT_ENTER, NODE_TEXT      ],
    [ EVENT_EXIT,  NODE_STRONG    ],
    [ EVENT_EXIT,  NODE_EMPH      ],
    [ EVENT_EXIT,  NODE_PARAGRAPH ],
    [ EVENT_EXIT,  NODE_ITEM      ],
    [ EVENT_EXIT,  NODE_LIST      ],
    [ EVENT_EXIT,  NODE_ITEM      ],
    [ EVENT_ENTER, NODE_ITEM      ],
    [ EVENT_ENTER, NODE_PARAGRAPH ],
    [ EVENT_ENTER, NODE_TEXT      ],
    [ EVENT_EXIT,  NODE_PARAGRAPH ],
    [ EVENT_EXIT,  NODE_ITEM      ],
    [ EVENT_EXIT,  NODE_LIST      ],
    [ EVENT_EXIT,  NODE_DOCUMENT  ],
);

{
    my $iter = $doc->iterator;
    isa_ok($iter, 'CommonMark::Iterator', 'iterator');

    for (my $i = 0; $i < @expected_events; ++$i) {
        my ($ev_type, $node) = $iter->next;
        my $expected = $expected_events[$i];

        is($ev_type, $expected->[0], "event $i: next ev_type, list context");
        is($iter->get_event_type, $ev_type, "event $i: get_event_type");

        is($node->get_type, $expected->[1],
           "event $i: next node, list context");
        is($iter->get_node, $node, "event $i: get_node");
    }

    my @list = $iter->next;
    is(scalar(@list), 0, 'iterator done, list context');
}

{
    my $iter = $doc->iterator;

    for (my $i = 0; $i < @expected_events; ++$i) {
        my $ev_type  = $iter->next;
        my $expected = $expected_events[$i];
        is($ev_type, $expected->[0], "event $i: next ev_type, scalar context");
    }

    my $ev_type = $iter->next;
    is($ev_type, EVENT_DONE, 'iterator done, scalar context');
}

{
    my $iter = $doc->iterator;

    # Make sure iterator survives destruction of document.
    $doc  = undef;
    # Cause some allocations.
    CommonMark->parse_document($md)
        for 1..5;

    my $num  = 0;

    $iter->next for 1..11;
    my $strong = $iter->get_node;
    is($strong->get_type, NODE_STRONG, '11th node is strong');

    $iter = undef;
    # Cause some allocations.
    CommonMark->parse_document($md)
        for 1..5;

    my $literal = $strong->first_child->get_literal;
    is($literal, 'Text', 'node survives destruction of iter');
}

