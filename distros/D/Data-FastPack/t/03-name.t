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


done_testing;
####################################################################################
# use Data::FastPack::Scoped;                                                      #
#                                                                                  #
#                                                                                  #
# use Data::Dumper;                                                                #
# use feature ":all";                                                              #
#                                                                                  #
# my $buf="";                                                                      #
# my $root=create_entry 0, "test", "user", 1;                                      #
# #say STDERR Dumper $root;                                                        #
#                                                                                  #
# my $child1=create_entry 1, "test1", "user1",1;                                   #
# my $child2=create_entry 2, "test2", "user2";                                     #
# #say STDERR Dumper $child1;                                                      #
# #say STDERR Dumper $child2;                                                      #
# #                                                                                #
# add_entry $child1, $child2;                                                      #
# add_entry $root, $child1;                                                        #
#                                                                                  #
# #say STDERR Dumper $root;                                                        #
#                                                                                  #
# encode_named_message $root, $buf, [[0.0, "test1", "hello"],[0,"test2","there"]]; #
#                                                                                  #
# my @output;                                                                      #
# decode_named_message $root, $buf, \@output;                                      #
#                                                                                  #
# say STDERR Dumper \@output;                                                      #
#                                                                                  #
# my $e=resolve $root, "test1";                                                    #
# ok $e==$child1, "Resolved ok";                                                   #
#                                                                                  #
# $e=resolve $root, "test1", "test2";                                              #
# ok $e==$child2, "Resolved ok";                                                   #
#                                                                                  #
# say STDERR "WHAT IS THE PARENT", Dumper $e;                                      #
# remove_entry $child1, $e;                                                        #
# $e=resolve $child1, "test2";                                                     #
# ok $e==undef, "Resolved ok";                                                     #
# done_testing;                                                                    #
####################################################################################
