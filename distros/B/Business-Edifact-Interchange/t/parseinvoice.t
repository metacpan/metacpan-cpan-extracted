use Test::More tests => 18;

use Business::Edifact::Interchange;

my $edi = Business::Edifact::Interchange->new;

$edi->parse_file('examples/INVOIC_019371B.CEI');
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

is( $messages->[0]->date_of_message(), '20111124', 'message date returned' );

cmp_ok( $messages->[0]->{supplier_vat_number},
    'eq', '153400995', 'supplier vat number returned' );

cmp_ok( $messages->[0]->{currency}->[1], 'eq', 'GBP', 'currency returned' );

cmp_ok( $messages->[0]->{payment_terms}->{type},
    'eq', 'fixed_date', 'payment terms returned' );

my $moa_values = @{$messages->[0]->{monetary_amount}};
cmp_ok( $moa_values, '==', 8, 'message level monetary values returned');

my $invoicelines = $messages->[0]->items();

isa_ok( $invoicelines->[0], 'Business::Edifact::Message::LineItem' );

cmp_ok( $invoicelines->[3]->{item_number},
    'eq', '9781846554070', 'EAN for invoice line returned' );

cmp_ok( $invoicelines->[3]->{quantity_invoiced},
    '==', 2, 'invoiced qty returned' );

my $e = Business::Edifact::Interchange->new;

$e->parse_file('examples/2_BLSINV224768.CEI');
my $inv       = $e->messages();
my $inv_lines = $inv->[0]->items();

cmp_ok( $inv_lines->[1]->{price}->[0]->{qualifier},
    'eq', 'AAA', 'price qualifier returned' );

cmp_ok( $inv_lines->[1]->{price}->[1]->{qualifier},
    'eq', 'AAB', 'second price qualifier returned' );

cmp_ok( $inv_lines->[1]->{price}->[0]->{price}, '==', 7.55, 'price returned' );

cmp_ok( $inv_lines->[1]->{price}->[1]->{price},
    '==', 8.99, 'second price returned' );

my $test_message =
q{UNA:+.? 'UNB+UNOC:3+1234567890123:14+3210987654321:14+131021:1523+391'UNH+1+INVOIC:D:96A:UN:EAN008'BGM+380+1077642090+9'DTM+137:20111020:102'DTM+35:20111020:102'FTX+AAK+1+ST2++DE'FTX+SUR+1++DAS LEISTUNGSDATUM ENTSPRICHT DEM RECHNUNGSDATUM+DE'RFF+ON:2330-35573'RFF+DQ:283506034'DTM+171:20111018:102'RFF+ABO:1087211625'DTM+171:20111020:102'NAD+BY+3210987654321::9'RFF+VA:230/5740/0622'RFF+API:3508566'NAD+DP+4050964023306::9'NAD+SU+1234567890123::9'RFF+VA:DE220564280'TAX+7+VAT+++:::7+S'CUX+2:EUR:4'LIN+1++1234567654321:EN'PIA+1+03460262:SA::91'IMD+A++:::NESLR Focaccia (24x400g) DE'IMD+C++IN'QTY+47:1:PCE'MOA+203:32.65'MOA+131:-12.95'PRI+AAB:45.6:::1:PCE'ALC+A+1++1+DI'MOA+8:12.95'RTE+1:12.95'LIN+2++1234567654321:EN+1:1'IMD+C++CU'QTY+59:1:PCE'UNS+S'MOA+77:34.94'MOA+79:32.65'MOA+125:32.65'MOA+124:2.29'TAX+7+VAT+++:::7+S'MOA+79:32.65'MOA+124:2.29'TAX+7+VAT+++:::7+S'MOA+125:32.65'UNT+44+1'UNH+2+INVOIC:D:96A:UN:EAN008'BGM+393+1087211625+9'DTM+137:20111020:102'NAD+CPE+3210987654321::9'RFF+FC:230/5740/0622'NAD+SU+1234567890123::9'RFF+VA:DE220564280'NAD+PR+3210987654321::9'NAD+PE+1234567890123::9'TAX+7+VAT+++:::7+S'CUX+2:EUR:4'PAT+3'DTM+13:20111025:102'UNS+S'MOA+86:34.94'MOA+9:34.94'MOA+124:2.29'MOA+125:32.65'UNT+19+2'UNZ+2+391'};

my $edi2 = Business::Edifact::Interchange->new;

$edi2->parse($test_message);

$inv = $edi2->messages();

my $inv_txt = $inv->[0]->{free_text};

cmp_ok( $inv_txt->[0]->{qualifier},
    'eq', 'AAK', 'invoice level free text returned' );

