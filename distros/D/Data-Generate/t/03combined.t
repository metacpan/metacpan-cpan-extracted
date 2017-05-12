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
$test->{varchar_01}->{text}= q { VC(5) 'ABC'[14]{2}'D'  };
$test->{varchar_01}->{get_degrees_of_freedom_result}= 4;
$test->{varchar_01}->{get_unique_data_input}= 5;
$test->{varchar_01}->{get_unique_data_result}= 4;
$test->{varchar_01}->{result_fully_booked}= ['ABC11','ABC14','ABC41','ABC44'];

# varchar test2
$test->{varchar_02}->{text}= q { VC(24) [1..2][14]   };
$test->{varchar_02}->{get_degrees_of_freedom_result}= 4;
$test->{varchar_02}->{get_unique_data_input}= 4;
$test->{varchar_02}->{get_unique_data_result}= 4;
$test->{varchar_02}->{result_fully_booked}= [11,14,21,24];

# varchar test3
$test->{varchar_03}->{text}= q { VC(24) [^0-z]   };
$test->{varchar_03}->{get_degrees_of_freedom_result}= 181;
$test->{varchar_03}->{get_unique_data_input}= 5;
$test->{varchar_03}->{get_unique_data_result}= 5;
$test->{varchar_03}->{result_fully_booked}= undef;


# float test1
$test->{float_01}->{text}=  q { 
 FLOAT (9) - 1  . [1,2] (50%) | 
  + 3  . 0 [0,6] (50%)  
 };
$test->{float_01}->{get_degrees_of_freedom_result}= 4;
$test->{float_01}->{get_unique_data_input}= 3;
$test->{float_01}->{get_unique_data_result}= 3;
$test->{float_01}->{result_fully_booked}= [ 
'-1.1','-1.2','3','3.06'];


# ---------------------------------------------------
# testplan
# ---------------------------------------------------
my @modes = ('varchar_01','varchar_02','varchar_03'
,'float_01'); 
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
my @fully_booked=sort{ $a cmp $b } (@{$generator->get_unique_data($freedom)});

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

