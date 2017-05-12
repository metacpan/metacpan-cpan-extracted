use Test::More tests => 16;

use Business::Edifact::Interchange;

my $edi = Business::Edifact::Interchange->new;

$edi->parse_file('examples/test2qty.ceq');

my $messages = $edi->messages();

isa_ok( $messages->[0], 'Business::Edifact::Message' );

my $msg_cnt = @{$messages};

cmp_ok( $msg_cnt, '==', 1, 'number of messages returned' );

is( $messages->[0]->type(), 'QUOTES', 'message type returned' );

is( $messages->[0]->function(), 'original', 'message function type returned' );

is( $messages->[0]->date_of_message(), '20110524', 'message date returned' );

my $items = $messages->[0]->items();

isa_ok( $items->[0], 'Business::Edifact::Message::LineItem' );

my $rel_nums = $items->[0]->related_numbers();
my $rn       = @{$rel_nums};
cmp_ok( $rn, '==', 2, 'correct number of related_number fields' );

cmp_ok( $rel_nums->[0]->{id},       'eq', '001', 'copy number returned' );
cmp_ok( $rel_nums->[0]->{LLO}->[0], 'eq', 'HLE', 'branch returned' );
cmp_ok( $rel_nums->[0]->{LFN}->[0],
    'eq', 'HLEAFI_T', 'fund allocation returned' );
cmp_ok( $rel_nums->[0]->{LST}->[0], 'eq', 'PBK', 'stock category returned' );
cmp_ok( $rel_nums->[0]->{LSQ}->[0], 'eq', 'T',   'collection code returned' );

cmp_ok( $rel_nums->[1]->{LLO}->[0], 'eq', 'COLLRD', 'copy 2 branch returned' );
cmp_ok( $rel_nums->[1]->{LFN}->[0],
    'eq', '320BOO', 'copy 2 fund allocation returned' );
cmp_ok( $rel_nums->[1]->{LST}->[0],
    'eq', '2WEEK', 'copy 2 stock category returned' );
cmp_ok( $rel_nums->[1]->{LSQ}->[0],
    'eq', 'MAIN', 'copy 2 collection code returned' );
