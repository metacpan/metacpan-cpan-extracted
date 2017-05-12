# Test Basic library functionality
use strict;
use warnings;
use Test::More;
use  Data::Generate  ':all';



# ---------------------------------------------------
# test input data
# ---------------------------------------------------
my $test={};
# string test , only few because functionality is covered by varchar type  
$test->{string_01}->{text}= q { STRING  [0-1] 'IM_A_VERY_LONG_STRING'{3}  };
$test->{string_01}->{get_degrees_of_freedom_result}= 2;
$test->{string_01}->{get_unique_data_input}= 2;
$test->{string_01}->{get_unique_data_result}= 2;
$test->{string_01}->{result_fully_booked}= [
  '0IM_A_VERY_LONG_STRINGIM_A_VERY_LONG_STRINGIM_A_VERY_LONG_STRING'
,  '1IM_A_VERY_LONG_STRINGIM_A_VERY_LONG_STRINGIM_A_VERY_LONG_STRING'
];


# varchar test  
$test->{varchar_01}->{text}= q { VC(24) [q-z] };
$test->{varchar_01}->{get_degrees_of_freedom_result}= 10;
$test->{varchar_01}->{get_unique_data_input}= 5;
$test->{varchar_01}->{get_unique_data_result}= 5;
$test->{varchar_01}->{result_fully_booked}= ['q','r','s','t','u'
,'v','w','x','y','z'];
# varchar test2
$test->{varchar_02}->{text}= q { VC(24) 'S'  };
$test->{varchar_02}->{get_degrees_of_freedom_result}= 1;
$test->{varchar_02}->{get_unique_data_input}= 1;
$test->{varchar_02}->{get_unique_data_result}= 1;
$test->{varchar_02}->{result_fully_booked}= ['S'];

# varchar test3
$test->{varchar_03}->{text}= q { VC(24) [1..10]  };
$test->{varchar_03}->{get_degrees_of_freedom_result}= 10;
$test->{varchar_03}->{get_unique_data_input}= 5;
$test->{varchar_03}->{get_unique_data_result}= 5;
# varchar test 4
$test->{varchar_04}->{text}= q { VC(24) [qza]  };
$test->{varchar_04}->{get_degrees_of_freedom_result}= 3;
$test->{varchar_04}->{get_unique_data_input}= 3;
$test->{varchar_04}->{get_unique_data_result}= 3;
$test->{varchar_04}->{result_fully_booked}= ['a','q','z'];


# varchar test 5 (file test)
$test->{varchar_05}->{text}=  q { 
VC(24)  <./t/vclist_01.txt> <./t/vclist_02.txt>  };
$test->{varchar_05}->{get_degrees_of_freedom_result}= 10;
$test->{varchar_05}->{get_unique_data_input}= 3;
$test->{varchar_05}->{get_unique_data_result}= 3;
$test->{varchar_05}->{result_fully_booked}= [
' a',' b','4a','4b','ONEa','ONEb','THREEa','THREEb','TWOa','TWOb'];

# date test 1
$test->{date_01}->{text}= q { 
     DATE [2005-2006][01-3][2-4] [11-15] : [11-15] : [11-15] (100%)  };
$test->{date_01}->{get_degrees_of_freedom_result}= 2250;
$test->{date_01}->{get_unique_data_input}= 3;
$test->{date_01}->{get_unique_data_result}= 3;

# date test 2
$test->{date_02}->{text}= q { 
     DATE 1995 01 [07-08,22]  11:12:24   };
$test->{date_02}->{get_degrees_of_freedom_result}= 3;
$test->{date_02}->{get_unique_data_input}= 6;
$test->{date_02}->{get_unique_data_result}= 3;
$test->{date_02}->{result_fully_booked}= ['19950107 11:12:24'
     ,'19950108 11:12:24','19950122 11:12:24'];


# date test 3
$test->{date_03}->{text}= q { 
     DATE [1999,2006][09,nov][07,mon,thu-fri] 09 : 09 : 09 <100%>  };
$test->{date_03}->{get_degrees_of_freedom_result}= 55;
$test->{date_03}->{get_unique_data_input}= 12;
$test->{date_03}->{get_unique_data_result}= 12;
$test->{date_03}->{result_fully_booked}= [
'19990902 09:09:09','19990903 09:09:09','19990906 09:09:09','19990907 09:09:09',
'19990909 09:09:09','19990910 09:09:09','19990913 09:09:09','19990916 09:09:09',
'19990917 09:09:09','19990920 09:09:09','19990923 09:09:09','19990924 09:09:09',
'19990927 09:09:09','19990930 09:09:09','19991101 09:09:09','19991104 09:09:09',
'19991105 09:09:09','19991107 09:09:09','19991108 09:09:09','19991111 09:09:09',
'19991112 09:09:09','19991115 09:09:09','19991118 09:09:09','19991119 09:09:09',
'19991122 09:09:09','19991125 09:09:09','19991126 09:09:09','19991129 09:09:09',
'20060901 09:09:09','20060904 09:09:09','20060907 09:09:09','20060908 09:09:09',
'20060911 09:09:09','20060914 09:09:09','20060915 09:09:09','20060918 09:09:09','20060921 09:09:09',
'20060922 09:09:09','20060925 09:09:09','20060928 09:09:09','20060929 09:09:09',
'20061102 09:09:09','20061103 09:09:09','20061106 09:09:09','20061107 09:09:09',
'20061109 09:09:09','20061110 09:09:09','20061113 09:09:09','20061116 09:09:09',
'20061117 09:09:09','20061120 09:09:09','20061123 09:09:09','20061124 09:09:09',
'20061127 09:09:09','20061130 09:09:09'
];


# date test 4
$test->{date_04}->{text}= q { 
     DATE (14) <./t/datelist_01.txt>    };
$test->{date_04}->{get_degrees_of_freedom_result}= 5;
$test->{date_04}->{get_unique_data_input}= 2;
$test->{date_04}->{get_unique_data_result}= 2;
$test->{date_04}->{result_fully_booked}= [ '19941116 22:28:20.00000000000000'
,'19950124 09:08:17.12345678901235','19981112 10:02:18.00000000000000'
,'19991112 10:02:18.00000000000000','20080229 22:28:20.00000000000000'];



# date test 5
$test->{date_05}->{text}= q { 
  DATE (4) 1999 09 15 09:09:09.[0,12][0-1][0-1] };
$test->{date_05}->{get_degrees_of_freedom_result}= 8;
$test->{date_05}->{get_unique_data_input}= 2;
$test->{date_05}->{get_unique_data_result}= 2;
$test->{date_05}->{result_fully_booked}= [ 
'19990915 09:09:9.0000','19990915 09:09:9.0010',
'19990915 09:09:9.0100','19990915 09:09:9.0110',
'19990915 09:09:9.1200','19990915 09:09:9.1201',
'19990915 09:09:9.1210','19990915 09:09:9.1211'];


# int test 1
$test->{int_01}->{text}=  q { 
    INT (9) +/- [3,0] [21,3,0] [4,0]  };

$test->{int_01}->{get_degrees_of_freedom_result}= 23;
$test->{int_01}->{get_unique_data_input}= 4;
$test->{int_01}->{get_unique_data_result}= 4;
$test->{int_01}->{result_fully_booked}= [
'-210','-214','-30','-300','-304','-3210','-3214','-330','-334','-34','-4','0',
'210','214','30','300','304','3210','3214','330','334','34','4'];



# int test 2
$test->{int_02}->{text}=  q { 
     INT    - 0[0,00-000]  [1,01-020]   };

$test->{int_02}->{get_degrees_of_freedom_result}= 20;
$test->{int_02}->{get_unique_data_input}= 20;
$test->{int_02}->{get_unique_data_result}= 20;
$test->{int_02}->{result_fully_booked}= [
'-1','-10','-11','-12','-13','-14','-15','-16','-17','-18','-19','-2',
'-20','-3','-4','-5','-6','-7','-8','-9'];

# int test 3
$test->{int_03}->{text}=  q { 
INT  <./t/numberlist_01.txt>{3}  };
$test->{int_03}->{get_degrees_of_freedom_result}= 64;
$test->{int_03}->{get_unique_data_input}= 4;
$test->{int_03}->{get_unique_data_result}= 4;
$test->{int_03}->{result_fully_booked}= [ 
'0','3','30','300','303','304','30456','33','330','333','334','33456',
'34','340','343','344','34456','3456','34560','34563','34564','3456456',
'4','40','400','403','404','40456','43','430','433','434','43456','44',
'440','443','444','44456','4456','44560','44563','44564','4456456','456'
,'4560','45600','45603','45604','4560456','4563','45630','45633','45634'
,'4563456','4564','45640','45643','45644','4564456','456456','4564560'
,'4564563','4564564','456456456'];

# float test 1
$test->{float_01}->{text}=  q { 
FLOAT (9) +/- [3,0] [2,3,0] . [0,5][3,0] E - 12 };
$test->{float_01}->{get_degrees_of_freedom_result}= 47;
$test->{float_01}->{get_unique_data_input}= 14;
$test->{float_01}->{get_unique_data_result}= 14;
$test->{float_01}->{result_fully_booked}= [ 
'-2.03e-12','-2.53e-12','-2.5e-12'
,'-2e-12','-3.003e-11','-3.03e-12','-3.053e-11','-3.05e-11'
,'-3.203e-11','-3.253e-11','-3.25e-11','-3.2e-11','-3.303e-11','-3.353e-11',
'-3.35e-11','-3.3e-11','-3.53e-12','-3.5e-12','-3e-11','-3e-12','-3e-14','-5.3e-13'
,'-5e-13','0','2.03e-12','2.53e-12','2.5e-12','2e-12','3.003e-11','3.03e-12'
,'3.053e-11','3.05e-11','3.203e-11','3.253e-11','3.25e-11','3.2e-11','3.303e-11'
,'3.353e-11','3.35e-11','3.3e-11','3.53e-12','3.5e-12','3e-11','3e-12','3e-14'
,'5.3e-13','5e-13'];


# float test 2
$test->{float_02}->{text}=  q { 
    FLOAT (14) <./t/numberlist_02.txt>  };
$test->{float_02}->{get_degrees_of_freedom_result}= 6;
$test->{float_02}->{get_unique_data_input}= 4;
$test->{float_02}->{get_unique_data_result}= 4;
$test->{float_02}->{result_fully_booked}= [ '-5e-06','0','11.5','390000000000'
,'43','4536'];

# ---------------------------------------------------
# testplan
# ---------------------------------------------------
my @modes = ('string_01','varchar_01','varchar_02','varchar_03'
,'varchar_04','varchar_05',
'date_01','date_02','date_03','date_04','date_05',
'int_01','int_02','int_03',
'float_01','float_02'); 
#@modes = ('float_01'); 
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

#my @fully_booked=();

my @fully_booked=sort (@{$generator->get_unique_data($freedom)});

my $fb_str=join('<,>',@fully_booked);
# diag(('get_unique_data() for expression:'.$test->{$mode}->{text}."\n",$fb_str));

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

