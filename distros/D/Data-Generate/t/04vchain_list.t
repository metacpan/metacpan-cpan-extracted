# Test Basic library functionality
use strict;
use warnings;
use Test::More;
use  Data::Generate  ':all';
use Test::More ;


# ---------------------------------------------------
# test input data
# ---------------------------------------------------
my $test={};
# varchar test
$test->{varchar_01}->{text}= q { VC(24) [14][2579]{4} (36%) | [A-G]{2}[X-Z][QN] (64%)  };
$test->{varchar_01}->{get_degrees_of_freedom_result}= 459;
$test->{varchar_01}->{get_unique_data_input}= 100;
$test->{varchar_01}->{get_unique_data_result}= 100;
$test->{varchar_01}->{regex_search}=['^\d+$','^[A-Z]+$'];
$test->{varchar_01}->{regex_search_result}=[36,64];


# date test 1
$test->{date_01}->{text}= q { 
     DATE [1985-1986][01-3][2-4] [11-15] : [11-15] : [11-15] (50%) |
          1998[01-03,08-09][07-15,22] 11:12:24 (25%) |
          [2001,2006][09,nov][07,mon,thu-fri] 09 : 09 : 09 (25%)   };
$test->{date_01}->{get_degrees_of_freedom_result}= 200;
$test->{date_01}->{get_unique_data_input}= 200;
$test->{date_01}->{get_unique_data_result}= 200;
$test->{date_01}->{regex_search}=['^198','^199' ,'^20'];
$test->{date_01}->{regex_search_result}=[100,50,50];

# integer test
$test->{integer_01}->{text}= q { INT(9) [1,4][2,5,7,9]{4} (36%) | [5-9]{2}[0-7][1,2] (64%)  };
$test->{integer_01}->{get_degrees_of_freedom_result}= 625;
$test->{integer_01}->{get_unique_data_input}= 100;
$test->{integer_01}->{get_unique_data_result}= 100;
$test->{integer_01}->{regex_search}=['^[14]\d+$','^[5-9].+$'];
$test->{integer_01}->{regex_search_result}=[36,64];


# float test 1
$test->{float_01}->{text}=  q { 
 FLOAT (9)  - 1 [0-9]{2} [1-5]. [1,2]{2} (25%) | 
  + 3 [0-9]{2} [1-5] . [5,6]{2} (12.5%) | 
  + 4 [0-9]{2} [1-5]. [7,8]{2} (12.5%) | 
  - 6 [0-9]{2} [1-5]. [3,4]{2} (50%)  
 };
$test->{float_01}->{get_degrees_of_freedom_result}= 4000;
$test->{float_01}->{get_unique_data_input}= 512;
$test->{float_01}->{get_unique_data_result}= 512;
$test->{float_01}->{regex_search}=['\.[1-2]{2}$','\.[5-6]{2}$','\.[7-8]{2}$','\.[3-4]{2}$'];
$test->{float_01}->{regex_search_result}=[128,64,64,256];


# ---------------------------------------------------
# testplan
# ---------------------------------------------------
my @modes = ('varchar_01','date_01','integer_01','float_01'); 
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

my $regex_search=$test->{$mode}->{regex_search};
my $regex_query_result=[];
foreach my $match (@$regex_search)
{
  my $cnt=0;
  foreach my $data (@$array)
  {
    $cnt++ if $data =~ /$match/;
  }
  push(@$regex_query_result,$cnt);
}


is(eq_array($regex_query_result, 
         $test->{$mode}->{regex_search_result}),1, 
         'query of array data distribution for expression:'.
              $test->{$mode}->{text})
or   diag('count query of array data distribution for expression:'.$test->{$mode}->{text}
   ."\n--------------------------------------\n",
  ' expected counts ----> '.join(',',@{$test->{$mode}->{regex_search_result}})
   ."\n--------------------------------------\n"
   .' result   counts ----> '.join(',',@$regex_query_result)
            ."\n--------------------------------------");


}

