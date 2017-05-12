# Test Basic library functionality
use strict;
use warnings;
use Test::More;
use  Data::Generate  ':all';
use Test::More 'no_diag';


# ---------------------------------------------------
# test input data
# ---------------------------------------------------
my $test={};
# varchar test
$test->{varchar_01}->{text}= q { VC(24) [1-3]{3} };
$test->{varchar_01}->{get_degrees_of_freedom_result}= 27;
$test->{varchar_01}->{get_unique_data_input}= 5;
$test->{varchar_01}->{get_unique_data_result}= 5;
$test->{varchar_01}->{result_fully_booked}=[
'111','112','113','121','122','123','131','132','133','211',
'212','213','221','222','223','231','232','233',
'311','312','313','321','322','323','331','332','333'];

# varchar test2
$test->{varchar_02}->{text}= q { VC(24) 'Yes'{2}  };
$test->{varchar_02}->{get_degrees_of_freedom_result}= 1;
$test->{varchar_02}->{get_unique_data_input}= 1;
$test->{varchar_02}->{get_unique_data_result}= 1;
$test->{varchar_02}->{result_fully_booked}= ['YesYes'];

# varchar test3
$test->{varchar_03}->{text}= q { VC(24) [7..10]{2}   };
$test->{varchar_03}->{get_degrees_of_freedom_result}= 16;
$test->{varchar_03}->{get_unique_data_input}= 5;
$test->{varchar_03}->{get_unique_data_result}= 5;
$test->{varchar_03}->{result_fully_booked}= [
'1010','107','108','109','710','77','78','79','810','87',
'88','89','910','97','98','99'];

# varchar test3
$test->{varchar_03}->{text}= q { VC(24) [7..10]{2}   };
$test->{varchar_03}->{get_degrees_of_freedom_result}= 16;
$test->{varchar_03}->{get_unique_data_input}= 5;
$test->{varchar_03}->{get_unique_data_result}= 5;
$test->{varchar_03}->{result_fully_booked}= [
'1010','107','108','109','710','77','78','79','810','87',
'88','89','910','97','98','99'];

# date test 1
$test->{date_01}->{text}= q { 
  DATE (4) 1999 09 09  09 : 09 : 09 .[0,5]{3} };
$test->{date_01}->{get_degrees_of_freedom_result}= 8;
$test->{date_01}->{get_unique_data_input}= 3;
$test->{date_01}->{get_unique_data_result}= 3;
$test->{date_01}->{result_fully_booked}= [
'19990909 09:09:9.0000','19990909 09:09:9.0050','19990909 09:09:9.0500'
,'19990909 09:09:9.0550','19990909 09:09:9.5000','19990909 09:09:9.5050'
,'19990909 09:09:9.5500','19990909 09:09:9.5550'
];


# float test 1
$test->{float_01}->{text}=  q { 
 FLOAT (9) +/- [3,0]{2} . [0,5]{2}};

$test->{float_01}->{get_degrees_of_freedom_result}= 31;
$test->{float_01}->{get_unique_data_input}= 14;
$test->{float_01}->{get_unique_data_result}= 14;
$test->{float_01}->{result_fully_booked}= [ 
'-0.05','-0.5','-0.55','-3','-3.05','-3.5','-3.55','-30','-30.05','-30.5'
,'-30.55','-33','-33.05','-33.5','-33.55','0','0.05','0.5','0.55','3'
,'3.05','3.5','3.55','30','30.05','30.5','30.55','33','33.05','33.5'
,'33.55'];

# ---------------------------------------------------
# testplan
# ---------------------------------------------------
my @modes = ('varchar_01','varchar_02','varchar_03'
,'date_01'
,'float_01'
); 
plan tests => (4 * @modes);

# ---------------------------------------------------
# testrun
# ---------------------------------------------------
foreach my $m (@modes) {
    unit_test($m,$test);
}
exit;



##########################
# unit test routine
##########################
sub unit_test {
   my $mode = shift;
   my $test = shift;


my $generator=parse($test->{$mode}->{text});

# ---------------------------------------------------
# start the tests
# ---------------------------------------------------
isnt($generator, 0, 
   'parse() for expression:'.$test->{$mode}->{text});

my $freedom= $generator->get_degrees_of_freedom();
is($freedom, 
    $test->{$mode}->{get_degrees_of_freedom_result}, 
   'get_degrees_of_freedom() for expression:'.
                 $test->{$mode}->{text},);

my $array=$generator->get_unique_data($test->{$mode}->{get_unique_data_input});
is(@$array, $test->{$mode}->{get_unique_data_result}, 
   'get_unique_data() for expression:'.
             $test->{$mode}->{text});
my @fully_booked=sort(@{$generator->get_unique_data($freedom)});

my $fb_str=join("\n",@fully_booked);
 diag(('get_unique_data() for expression:'.$test->{$mode}->{text}."\n",$fb_str));

SKIP: {
        skip "comparison data not availables",1 
           unless defined $test->{$mode}->{result_fully_booked};
      is(eq_array(\@fully_booked, 
#        \@fully_booked ),1, 
         $test->{$mode}->{result_fully_booked}),1, 
         'test array (sorted) result of get_unique_data(maxcard) for expression:'.
              $test->{$mode}->{text});
    }

}

