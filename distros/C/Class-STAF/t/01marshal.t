use strict;
#use lib '../lib';
use Class::STAF;
use Test::Simple tests=>4;
use Data::Dumper;
my $data =
'@SDT/*:267:@SDT/{:26::13:map-class-map@SDT/{:0:@SDT/[10:218:@SDT/$S:11:STAFTcl.h'. 
'tm@SDT/$S:12:STAFPerl.htm@SDT/$S:14:STAFPython.htm@SDT/$S:7:History@SDT/$S:12:ST'. 
'AFCMDS.htm@SDT/$S:11:STAFFAQ.htm@SDT/$S:10:STAFGS.pdf@SDT/$S:12:STAFHome.htm@SDT'.
'/$S:10:STAFRC.htm@SDT/$S:10:STAFUG.htm';

my $array = [
    'STAFTcl.htm',
    'STAFPerl.htm',
    'STAFPython.htm',
    'History',
    'STAFCMDS.htm',
    'STAFFAQ.htm',
    'STAFGS.pdf',
    'STAFHome.htm',
    'STAFRC.htm',
    'STAFUG.htm'
];

my $fail = 0;
my $array2 = UnMarshall($data);
if (@$array != @$array2) {
    warn "the two arrays are not even in the same lenght!";
    $fail = 1;
} else {
    for (my $ix=0; $ix<@$array; $ix++) {
        $fail = 1 if $array->[$ix] ne $array2->[$ix];
    }
}
ok($fail == 0, "UnMarshall a simple array");
ok($data eq Marshall($array), "Marshall a simple array");

my $class_string = 
'@SDT/*:372:@SDT/{:290::13:map-class-map@SDT/{:262::24:STAF/Service/Var/VarInfo'. 
'@SDT/{:223::4:keys@SDT/[3:162:@SDT/{:44::12:display-name@SDT/$S:1:X:3:key'. 
'@SDT/$S:1:X@SDT/{:44::12:display-name@SDT/$S:1:Y:3:key@SDT/$S:1:Y'. 
'@SDT/{:44::12:display-name@SDT/$S:1:Z:3:key@SDT/$S:1:Z:4:name'. 
'@SDT/$S:24:STAF/Service/Var/VarInfo@SDT/%:61::24:STAF/Service/Var/VarInfo'.
'@SDT/$S:1:3@SDT/$S:1:4@SDT/$S:1:5';

my $class_ref = {
    'Z' => '5',
    'X' => '3',
    'Y' => '4'
};

my $class_ref2 = UnMarshall($class_string);

$fail = 0;
if (scalar(keys %$class_ref2) != scalar(keys %$class_ref)) {
    warn "the two hashes are not even in the same lenght!";
    $fail = 1;
} else {
    foreach my $key (keys %$class_ref) {
        $fail = 1
            unless  exists $class_ref2->{$key}
                    and $class_ref->{$key} eq $class_ref2->{$key};
    }
}
ok($fail==0, "UnMarshalling class data");
ok(Marshall(UnMarshall($class_string)) eq $class_string, "round trip of class data");

