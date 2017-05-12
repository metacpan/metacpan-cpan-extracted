use strict;
use Test::More tests => 1;
use Data::EDI::X12;

my $x12 = Data::EDI::X12->new({ spec_file => 't/loops.yaml', new_lines => 1, truncate_null => 1 });

my $string = q[ISA*00*          *00*          *12*9999999999     *12*8888888888     *160729*0730*U*00401*000000471*0*P*>~
GS*IN*9999999999*8888888888*20160729*0730*000000471*X*004010~
ST*810*2097~
BIG*20160728*0001373400*40140726*N333316-XXXX~
REF*IA*0000000000~
N1*ST*TEST TACO EXPRESS*92*0000~
N2*333 TACO TOWN LANE*PA*15219~
N1*ST*MAGIC SALAD EXPRESS*92*0000~
N2*666 FUN TOWN LANE*VA*22032~
DTM*011*20160727~
POP*HELLO~
ROCK*SKI~
POP*WORLD~
ROCK*SKIS~
IT1*1*2*EA*99.99**VN*STACO333~
PID*F****MAGIC TACO WITH SALAD~
IT1*1*2*EA*99.99**VN*STACO333~
PID*F****MAGIC TACO WITH SALAD~
TDS*19198~
CTT*1~
SE*19*2097~
GE*1*000000471~
IEA*1*000000471~
];

my $record = $x12->read_record($string);


my $out = $x12->write_record($record);

cmp_ok($string, 'eq', $out, 'Data::EDI::X12 generates a sane file with loops');



