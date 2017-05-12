use Test::More tests => 6;

use Business::Edifact::Interchange;

my $edi = Business::Edifact::Interchange->new;

$edi->parse_file('examples/SampleQuote.txt');

my $messages = $edi->messages();

isa_ok($messages->[0], 'Business::Edifact::Message');

my $msg_cnt = @{$messages};

cmp_ok($msg_cnt, '==', 1, 'number of messages returned');


is($messages->[0]->type(), 'QUOTES', 'message type returned');

is($messages->[0]->function(), 'original', 'message function type returned');

is($messages->[0]->date_of_message(), '20060223', 'message date returned');

my $items = $messages->[0]->items();

isa_ok($items->[0], 'Business::Edifact::Message::LineItem');


