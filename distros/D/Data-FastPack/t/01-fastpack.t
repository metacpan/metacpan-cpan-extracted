use strict;
use warnings;
use feature ":all";
use Test::More;


use Data::FastPack;
use Data::FastPack::Meta;

#use Data::Dumper;

my $buffer="";
my @input=([0, 1, "a"x7],[0,23,"b" x 7]);
my @input_copy=@input;
encode_message($buffer, \@input);

# Ensure padding is correct
ok length($buffer)%8 == 0, "Padding ok";


# Decode, gives length
my @output;
my $limit=10;
my $byte_count=decode_message($buffer, \@output, $limit);
#say STDERR Dumper @input;
#say STDERR Dumper @output;
ok length($buffer)==0, "Length ok";

ok @input_copy==@output, "Same message count";

# Test decoded messages are identical
for(0..$#input_copy){
  ok $input_copy[$_][0]==$output[$_][0];
  ok $input_copy[$_][1]==$output[$_][1];
  ok $input_copy[$_][2] eq $output[$_][2];
}


# Meta data
my $data={this=>1, is=>"text"};
my $json_payload=encode_meta_payload($data);
my $mp_payload=encode_meta_payload($data,1);

ok $json_payload =~ /^(\x58|\x7B)/, "JSON ok";

my $byte=unpack "C", $mp_payload;
# test fixed  complex
my $b=$byte&0xF0;
my $test=$b && 0x80;  #Fixmap
$test|= $b && 0x90;   #Fixarray

$test|= $byte==0xDC;  #Array 16
$test|= $byte==0xDD;  #Array 32
$test|= $byte==0xDE;  #Map 16
$test|= $byte==0xDF;  #Map 32

#
ok $test, "Structured MessagePack";
#say STDERR "JSON:". $json_payload;
#say STDERR "MP: ". unpack "H*", $mp_payload;

my $json_decode=decode_meta_payload($json_payload);
my $mp_decode=decode_meta_payload($mp_payload);


my @input_keys=sort keys %$data;
my @json_keys=sort keys %$json_decode;
my @mp_keys=sort keys %$mp_decode;

ok @json_keys==@input_keys, "json Key count ok";
ok @mp_keys==@input_keys, "mp Key count ok";


for(0..$#json_keys){
  ok $json_keys[$_] eq $input_keys[$_], "JSON Key comparision";
  ok $mp_keys[$_] eq $input_keys[$_], "MP Key comparision";
  ok $json_decode->{$json_keys[$_]} eq $data->{$input_keys[$_]}, "JSON value comparision";
  ok $mp_decode->{$json_keys[$_]} eq $data->{$input_keys[$_]}, "MP value comparision";
}
done_testing;
