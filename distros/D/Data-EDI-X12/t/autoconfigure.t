use strict;
use Test::More tests => 1;
use Data::EDI::X12;

my $string = q[ISA*00*          *00*          *01*012345675      *01*987654321      *140220*1100*^*00501*000000001*0*P*>|
GS*PO*012345675*987654321*20140220*1100*000000001*X*005010|
ST*850*0001|
BEG*00*KN*1136064**20140220|
DTM*002*20140220|
N9*ZA*0000010555|
N1*ST*U997*92*U997|
PO1**1*EA*1.11**UC*000000000007*PI*000000000000000004*VN*113|
PID*F****Test Product 1|
PO1**1*EA*2.22**UC*000000000008*PI*000000000000000005*VN*114|
PID*F****Test Product 2|
CTT*4*4|
SE*11*0001|
GE*1*000000001|
IEA*1*000000001|
];


my $x12 = Data::EDI::X12->new({ spec_file => 't/spec.yaml', new_lines => 1, truncate_null => 1, auto_configure => 1 });

my $record = $x12->read_record($string);

my $out = $x12->write_record($record);

cmp_ok($string, 'eq', $out, 'Data::EDI::X12 generates a sane file via autoconfigure');


