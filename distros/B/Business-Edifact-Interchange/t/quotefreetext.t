use Test::More tests => 7;

use Business::Edifact::Interchange;
use Data::Dumper;

my $edi = Business::Edifact::Interchange->new;

$edi->parse_file('examples/prquotes_73050_20110826.ceq');

my $messages = $edi->messages();

isa_ok( $messages->[0], 'Business::Edifact::Message' );

my $msg_cnt = @{$messages};

cmp_ok( $msg_cnt, '==', 1, 'number of messages returned' );

is( $messages->[0]->type(), 'QUOTES', 'message type returned' );

is( $messages->[0]->date_of_message(), '20110826', 'message date returned' );

my $items = $messages->[0]->items();

isa_ok( $items->[0], 'Business::Edifact::Message::LineItem' );

cmp_ok(
    $items->[1]->{free_text}->{text},
    'eq',
    'E*070.18*- Additional items',
    'Free text field returned'
);

cmp_ok(
    $items->[30]->{free_text}->{text},
    'eq',
    'E*343.0998 *- Additional items',
    'All free text fields returned'
);

