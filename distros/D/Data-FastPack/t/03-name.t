use Test::More;
 
use Data::FastPack;

my $ns= create_namespace;

ok defined $ns;


my $buffer="";

encode_fastpack $buffer, [[0, "test/name", "data"]], undef, $ns;

my $id=id_for_name $ns, "test/name";

ok defined $id;

my @output;

my $ns2= create_namespace;
decode_fastpack $buffer, \@output, undef, $ns2;

ok @output==1, "decode ok";

my $id2=id_for_name $ns2, "test/name";
ok $id2==$id, "Matching ids";


# unregister

$buffer="";
@output=();
encode_fastpack $buffer, [[0, "test/name", undef]], undef, $ns;

$id=id_for_name $ns, "test/name";
ok !defined $id, "Encoding side name unregistered";

decode_fastpack $buffer, \@output, undef, $ns2;


ok @output==0, "Unregister filtered from output";

$id2=id_for_name $ns2, "test/name";
ok !defined $id2, "Decoding side name unregistred";

done_testing;

