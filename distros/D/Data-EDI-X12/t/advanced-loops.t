use strict;
use Test::More tests => 1;
use Data::EDI::X12;

my $x12 = Data::EDI::X12->new({ spec_file => 't/advanced-loops.yaml', new_lines => 1, truncate_null => 1 });

my $string = q[ISA*00*          *00*          *01*WISDOM         *01*               *181019*1611*^*00501*000010038*0*P*>~
GS*SH*WISDOM   *         *20181019*1611*000010038*X*005010~
ST*856*0001~
BSN*00*1*20181010*1611*0001~
DTM*011*20181010~
DTM*011*20181010~
MAN*011*20181010~
MAN*012*30181010~
HL*1**S~
TD5*B*2*UPSN*U~
REF*CN*UNKNOWN~
DTM*011*20181010~
N1*ST*Sally Simon*92~
N3*Wisdom~
N4*Lane~
HL*2*1*O~
TD1*CTN25*1~
N1*BY**92~
PID*S**VI*FL~
CTT*2~
SE*19*0001~
GE*1*000010038~
IEA*1*000010038~
];


my $record = $x12->read_record($string);
my $out    = $x12->write_record($record);

cmp_ok($string, 'eq', $out, 'Data::EDI::X12 generates a sane file with advanced loops');

