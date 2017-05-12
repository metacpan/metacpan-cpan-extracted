use Test::More tests => 25;

use Business::Edifact::Interchange;

my $edi = Business::Edifact::Interchange->new;

$edi->parse_file('examples/invoice_example');
my $messages = $edi->messages();

isa_ok( $messages->[0], 'Business::Edifact::Message' );

my $msg_cnt = @{$messages};

cmp_ok( $msg_cnt, '==', 1, 'number of messages returned' );

is( $messages->[0]->type(), 'INVOIC', 'message type returned' );

cmp_ok( $messages->[0]->message_code,
    'eq', '380', 'message code indicate invoice' );

is(
    $messages->[0]->function(),
    'additional transmission',
    'message function type returned'
);

is( $messages->[0]->date_of_message(), '20010831', 'message date returned' );

cmp_ok( $messages->[0]->{supplier_vat_number},
    'eq', '123456789', 'supplier vat number returned' );

#cmp_ok( $messages->[0]->{currency}->[1], 'eq', 'GBP', 'currency returned' );

cmp_ok( $messages->[0]->{payment_terms}->{type},
    'eq', 'basic', 'payment terms returned' );

cmp_ok( $messages->[0]->{payment_terms}->{terms}->[2],
    'eq', 'D', 'payment terms are in days' );
cmp_ok( $messages->[0]->{payment_terms}->{terms}->[3],
    '==', '30', 'payment terms are 30 days' );

my $moa_values = @{ $messages->[0]->{monetary_amount} };
cmp_ok( $moa_values, '==', 7, 'message level monetary values returned' );

cmp_ok( $messages->[0]->{summary_count},
    '==', 2, 'Correct number of line items returned' );

my $invoicelines = $messages->[0]->items();

isa_ok( $invoicelines->[0], 'Business::Edifact::Message::LineItem' );

cmp_ok( $invoicelines->[1]->{item_ID_number}->{number},
    'eq', '0140374132', 'ID for invoice line returned' );
cmp_ok( $invoicelines->[1]->{item_ID_number}->{type},
    'eq', 'ISBN', 'ID for invoice line is ISBN' );

cmp_ok( $invoicelines->[1]->{quantity_invoiced},
    '==', 3, 'invoiced qty returned' );

cmp_ok( $invoicelines->[1]->{lineitem_amount},
    '==', 10.77, 'lineitem amount returned' );

cmp_ok( $invoicelines->[1]->{price}->[0]->{qualifier},
    'eq', 'AAE', 'information price qualifier returned' );

cmp_ok( $invoicelines->[1]->{price}->[0]->{price},
    '==', 3.99, 'correct value for information price returned' );

cmp_ok( $invoicelines->[1]->{item_allowance_or_charge}->[0]->{service_code},
    'eq', 'DI', 'discount applicable returned' );

cmp_ok( $invoicelines->[1]->{item_allowance_or_charge}->[0]->{percentage},
    '==', 10, 'discount at 10 per cent returned' );

my $tax = $invoicelines->[1]->{tax}->[0];

cmp_ok( $tax->{function_code}, '==', 7, 'tax functon TAX returned' );

cmp_ok( $tax->{type_code}, 'eq', 'VAT', 'tax type retrieved as VAT' );

cmp_ok( $tax->{category_code}, 'eq', 'Z', 'tax retrieved as zero rated' );

cmp_ok( $invoicelines->[1]->{buyers_refnumber},
    'eq', 'BY99375', "invoice line buyer's ref number returned" );
