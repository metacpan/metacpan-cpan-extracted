use strict;
use warnings;

use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ?
    (tests => 1) :
    (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

use CommonMark qw(:node :event);

my $md = <<EOF;
normal, *emph*, **strong**
EOF

sub tree_manip {
    my $doc       = CommonMark->parse_document($md);
    my $paragraph = $doc->first_child;
    my $text      = $paragraph->first_child;
    my $emph      = $text->next;
    my $strong    = $paragraph->last_child;
    my $space     = $strong->previous;

    $doc = undef;

    my $result = CommonMark::Node->new(NODE_DOCUMENT);
    $text->unlink;
    $strong->unlink;
    $result->append_child($paragraph);
    $emph->insert_before($text);
    $space->insert_after($strong);
    $emph->replace($strong);
    $space->unlink;
}

sub iterate_list_context {
    my $doc  = CommonMark->parse_document($md);
    my $iter = $doc->iterator;
    my $sum  = 0;
    while (my ($ev_type, $node) = $iter->next) {
        $sum += $ev_type;
    }
    return $sum;
}

sub iterate_scalar_context {
    my $doc  = CommonMark->parse_document($md);
    my $iter = $doc->iterator;
    my $sum  = 0;
    while ((my $ev_type = $iter->next) != EVENT_DONE) {
        $sum += $ev_type;
    }
    return $sum;
}

sub aborted_iteration {
    my $doc  = CommonMark->parse_document($md);
    my $iter = $doc->iterator;
    my ($ev_type, $node);
    $ev_type = $iter->next;
    ($ev_type, $node) = $iter->next;
    $ev_type = $iter->next;
    ($ev_type, $node) = $iter->next;
}

sub parser {
    my $parser = CommonMark::Parser->new;
    $parser->feed("paragraph\n\n")
        for 1..5;
    $parser->finish;
}

no_leaks_ok {
    tree_manip();
    iterate_list_context();
    iterate_scalar_context();
    aborted_iteration();
    parser();
};

