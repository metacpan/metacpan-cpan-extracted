use Test::More;
 
use Data::FastPack;

{
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


  ###################################################################
  # # unregister                                                    #
  #                                                                 #
  # $buffer="";                                                     #
  # @output=();                                                     #
  # encode_fastpack $buffer, [[0, "test/name", undef]], undef, $ns; #
  #                                                                 #
  # $id=id_for_name $ns, "test/name";                               #
  # ok !defined $id, "Encoding side name unregistered";             #
  #                                                                 #
  # decode_fastpack $buffer, \@output, undef, $ns2;                 #
  #                                                                 #
  #                                                                 #
  # ok @output==0, "Unregister filtered from output";               #
  #                                                                 #
  # $id2=id_for_name $ns2, "test/name";                             #
  # ok !defined $id2, "Decoding side name unregistred";             #
  ###################################################################

}


# Test clearing of name space
{
  
  my $ns= create_namespace;
  ok defined $ns;

  my $buffer="";

  for(1..5){
    encode_fastpack $buffer, [[0, "test/ddname$_", "data$_"]], undef, $ns;
  }

  
  # Checking input name space
  for(1..5){
    my $id=id_for_name $ns, "test/ddname$_";
    ok defined $id;
    ok $id==$_;
  }
  ok keys($ns->[N2E]->%*) == 5;
  ok keys($ns->[I2E]->%*) == 5;

  
  # Clear name space with special message


  encode_fastpack $buffer, [[0, 0, undef]], undef, $ns;
  print STDERR "----- ". keys($ns->[N2E]->%*)."\n\n";

  # Should name no key
  
  ok keys($ns->[N2E]->%*) == 0;
  ok keys($ns->[I2E]->%*) == 0;

  my @output;



  # Now Process Decoding

  my $ns2= create_namespace;
  decode_fastpack $buffer, \@output, undef, $ns2;

  ok @output==5, "decode ok"; # meta messages removed before output

  for(1..5){
    my $id2=id_for_name $ns2, "test/ddname$_";
  }

  # 
  ok keys($ns2->[N2E]->%*) == 0;
  ok keys($ns2->[I2E]->%*) == 0;

}

done_testing;

