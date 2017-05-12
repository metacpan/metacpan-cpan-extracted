#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.06';   # automatically generated file
$DATE = '2004/05/11';


##### Demonstration Script ####
#
# Name: Secs2.d
#
# UUT: Data::Secs2
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Data::Secs2 
#
# Don't edit this test script file, edit instead
#
# t::Data::Secs2
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# The working directory is the directory of the generated file
#
use vars qw($__restore_dir__ @__restore_inc__ );

BEGIN {
    use Cwd;
    use File::Spec;
    use FindBin;
    use Test::Tech qw(demo is_skip plan skip_tests tech_config );

    ########
    # The working directory for this script file is the directory where
    # the test script resides. Thus, any relative files written or read
    # by this test script are located relative to this test script.
    #
    use vars qw( $__restore_dir__ );
    $__restore_dir__ = cwd();
    my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
    chdir $vol if $vol;
    chdir $dirs if $dirs;

    #######
    # Pick up any testing program modules off this test script.
    #
    # When testing on a target site before installation, place any test
    # program modules that should not be installed in the same directory
    # as this test script. Likewise, when testing on a host with a @INC
    # restricted to just raw Perl distribution, place any test program
    # modules in the same directory as this test script.
    #
    use lib $FindBin::Bin;

    unshift @INC, File::Spec->catdir( cwd(), 'lib' ); 

}

END {

    #########
    # Restore working directory and @INC back to when enter script
    #
    @INC = @lib::ORIG_INC;
    chdir $__restore_dir__;

}

print << 'MSG';

~~~~~~ Demonstration overview ~~~~~
 
The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

MSG

demo( "\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\
\ \ \ \ use\ Data\:\:Secs2\ qw\(arrayify\ config\ listify\ neuterify\ numberify\ perlify\ \
\ \ \ \ \ \ \ \ \ perl_typify\ secsify\ secs_elementify\ stringify\ textify\ transify\)\;\
\
\ \ \ \ my\ \$uut\ \=\ \'Data\:\:Secs2\'\;\
\ \ \ \ my\ \(\$loaded\,\ \$event\,\ \$big_secs2\)\;\
\
my\ \$test_data1\ \=\
\'U1\[1\]\ 80\
L\[5\]\
\ \ A\[0\]\
\ \ A\[5\]\ ARRAY\
\ \ N\ 2\
\ \ A\[5\]\ hello\
\ \ N\ 4\
\'\;\
\
my\ \$test_data2\ \=\
\'U1\[1\]\ 80\
L\[6\]\
\ \ A\[0\]\
\ \ A\[4\]\ HASH\
\ \ A\[4\]\ body\
\ \ A\[5\]\ hello\
\ \ A\[6\]\ header\
\ \ A\[9\]\ To\:\ world\
\'\;\
\
my\ \$test_data3\ \=\
\'U1\[1\]\ 80\
N\ 2\
L\[4\]\
\ \ A\[0\]\
\ \ A\[5\]\ ARRAY\
\ \ A\[5\]\ hello\
\ \ A\[5\]\ world\
N\ 512\
\'\;\
\
my\ \$test_data4\ \=\
\'U1\[1\]\ 80\
N\ 2\
L\[6\]\
\ \ A\[0\]\
\ \ A\[4\]\ HASH\
\ \ A\[6\]\ header\
\ \ L\[6\]\
\ \ \ \ A\[11\]\ Class\:\:None\
\ \ \ \ A\[4\]\ HASH\
\ \ \ \ A\[4\]\ From\
\ \ \ \ A\[6\]\ nobody\
\ \ \ \ A\[2\]\ To\
\ \ \ \ A\[6\]\ nobody\
\ \ A\[3\]\ msg\
\ \ L\[4\]\
\ \ \ \ A\[0\]\
\ \ \ \ A\[5\]\ ARRAY\
\ \ \ \ A\[5\]\ hello\
\ \ \ \ A\[5\]\ world\
\'\;\
\
my\ \$test_data5\ \=\
\'U1\[1\]\ 80\
L\[6\]\
\ \ A\[0\]\
\ \ A\[4\]\ HASH\
\ \ A\[6\]\ header\
\ \ L\[6\]\
\ \ \ \ A\[11\]\ Class\:\:None\
\ \ \ \ A\[4\]\ HASH\
\ \ \ \ A\[4\]\ From\
\ \ \ \ A\[6\]\ nobody\
\ \ \ \ A\[2\]\ To\
\ \ \ \ A\[6\]\ nobody\
\ \ A\[3\]\ msg\
\ \ L\[4\]\
\ \ \ \ A\[0\]\
\ \ \ \ A\[5\]\ ARRAY\
\ \ \ \ A\[5\]\ hello\
\ \ \ \ A\[5\]\ world\
L\[6\]\
\ \ A\[0\]\
\ \ A\[4\]\ HASH\
\ \ A\[6\]\ header\
\ \ L\[3\]\
\ \ \ \ A\[0\]\
\ \ \ \ A\[5\]\ Index\
\ \ \ \ N\ 10\
\ \ A\[3\]\ msg\
\ \ L\[3\]\
\ \ \ \ A\[0\]\
\ \ \ \ A\[5\]\ ARRAY\
\ \ \ \ A\[4\]\ body\
\'\;\
\
my\ \$test_data6\ \=\ \[\ \[78\,45\,25\]\,\ \[512\,1024\]\,\ 100000\ \]\;\
\
my\ \$test_data7\ \=\ \'a50150010541004105\'\ \.\ unpack\(\'H\*\'\,\'ARRAY\'\)\ \.\ \
\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \'a5034e2d19\'\ \.\ \ \'a90402000400\'\ \.\ \'b104000186a0\'\;\
\
my\ \$test_data17\ \=\ \'a50150010541004105\'\ \.\ unpack\(\'H\*\'\,\'ARRAY\'\)\ \.\ \
\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \'a5034e2d19\'\ \.\ \ \'a90402000400\'\ \.\ \'b0000186a0\'\;"); # typed in command           
          use File::Package;
    my $fp = 'File::Package';

    use Data::Secs2 qw(arrayify config listify neuterify numberify perlify 
         perl_typify secsify secs_elementify stringify textify transify);

    my $uut = 'Data::Secs2';
    my ($loaded, $event, $big_secs2);

my $test_data1 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  N 2
  A[5] hello
  N 4
';

my $test_data2 =
'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[4] body
  A[5] hello
  A[6] header
  A[9] To: world
';

my $test_data3 =
'U1[1] 80
N 2
L[4]
  A[0]
  A[5] ARRAY
  A[5] hello
  A[5] world
N 512
';

my $test_data4 =
'U1[1] 80
N 2
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
';

my $test_data5 =
'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[3]
    A[0]
    A[5] Index
    N 10
  A[3] msg
  L[3]
    A[0]
    A[5] ARRAY
    A[4] body
';

my $test_data6 = [ [78,45,25], [512,1024], 100000 ];

my $test_data7 = 'a50150010541004105' . unpack('H*','ARRAY') . 
                 'a5034e2d19' .  'a90402000400' . 'b104000186a0';

my $test_data17 = 'a50150010541004105' . unpack('H*','ARRAY') . 
                 'a5034e2d19' .  'a90402000400' . 'b0000186a0';; # execution

      #######
# multicell numberics, Perl Secs Object
#
my $test_data8 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  U1[3] 78 45 25
  U2[2] 512 1024
  U4[1] 100000
';


#######
# Strict Perl numberics, Perl Secs Object
#
my $test_data9 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  N[3] 78 45 25
  N[2] 512 1024
  N 100000
';

my $test_data10 =
'U1[1] 80
L[3]
  A[0]
  A[5] ARRAY
  L[5]
    A[0]
    A[5] ARRAY
    N 2
    A[5] hello
    N 4
';

my $test_data11 =
'U1[1] 80
L[3]
  A[0]
  A[5] ARRAY
  L[6]
    A[0]
    A[4] HASH
    A[4] body
    A[5] hello
    A[6] header
    A[9] To: world
';

my $test_data12 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  N 2
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
  N 512
';

my $test_data13 =
'U1[1] 80
L[4]
  A[0]
  A[5] ARRAY
  N 2
  L[6]
    A[0]
    A[4] HASH
    A[6] header
    L[6]
      A[11] Class::None
      A[4] HASH
      A[4] From
      A[6] nobody
      A[2] To
      A[6] nobody
    A[3] msg
    L[4]
      A[0]
      A[5] ARRAY
      A[5] hello
      A[5] world
';

my $test_data14 =
'U1[1] 80
L[4]
  A[0]
  A[5] ARRAY
  L[6]
    A[0]
    A[4] HASH
    A[6] header
    L[6]
      A[11] Class::None
      A[4] HASH
      A[4] From
      A[6] nobody
      A[2] To
      A[6] nobody
    A[3] msg
    L[4]
      A[0]
      A[5] ARRAY
      A[5] hello
      A[5] world
  L[6]
    A[0]
    A[4] HASH
    A[6] header
    L[3]
      A[0]
      A[5] Index
      N 16
    A[3] msg
    L[3]
      A[0]
      A[5] ARRAY
      A[4] body
';

my $test_data15 =
'U1[1] 80
U1[1] 2
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
';

my $test_data16 =
'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[3]
    A[0]
    A[5] Index
    U1 10
  A[3] msg
  L[3]
    A[0]
    A[5] ARRAY
    A[4] body
';


#######
# multicell numberics, Perl Secs Object
#
my $test_data18 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  U1[3] 78 45 25
  U2[2] 512 1024
  U4 100000
';

my $test_data19 =
'U1[1] 80
L[7]
  A[0]
  A[5] ARRAY
  N 2
  A[5] hello
  N 4
  N 0
  L[0]
';; # execution

print << "EOF";

 ##################
 # stringify an array
 # 
 
EOF

demo( "stringify\(\ \'2\'\,\ \'hello\'\,\ 4\ \)", # typed in command           
      stringify( '2', 'hello', 4 )); # execution


print << "EOF";

 ##################
 # stringify a hash reference
 # 
 
EOF

demo( "stringify\(\ \{header\ \=\>\ \'To\:\ world\'\,\ body\ \=\>\ \'hello\'\}\)", # typed in command           
      stringify( {header => 'To: world', body => 'hello'})); # execution


print << "EOF";

 ##################
 # ascii secsify lisfication of test_data1 an array reference
 # 
 
EOF

demo( "secsify\(\ listify\(\ \[\'2\'\,\ \'hello\'\,\ 4\,\ 0\,\ undef\]\ \)\ \)", # typed in command           
      secsify( listify( ['2', 'hello', 4, 0, undef] ) )); # execution


print << "EOF";

 ##################
 # ascii secsify lisfication of test_data3 - array with an array ref
 # 
 
EOF

demo( "secsify\(\ listify\(\ \'2\'\,\ \[\'hello\'\,\ \'world\'\]\,\ 512\ \)\ \)", # typed in command           
      secsify( listify( '2', ['hello', 'world'], 512 ) )); # execution


demo( "my\ \$obj\ \=\ bless\ \{\ To\ \=\>\ \'nobody\'\,\ From\ \=\>\ \'nobody\'\}\,\ \'Class\:\:None\'", # typed in command           
      my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None'); # execution


print << "EOF";

 ##################
 # ascii secsify lisfication of test_data5 - hash with nested hashes, arrays, common objects
 # 
 
EOF

demo( "\ \ \ \ secsify\(\ listify\(\ \{msg\ \=\>\ \[\'hello\'\,\ \'world\'\]\ \,\ header\ \=\>\ \$obj\ \}\,\ \
\ \ \ \ \ \{msg\ \=\>\ \[\ \'body\'\ \]\,\ header\ \=\>\ \$obj\}\ \)\ \)", # typed in command           
          secsify( listify( {msg => ['hello', 'world'] , header => $obj }, 
     {msg => [ 'body' ], header => $obj} ) )); # execution


print << "EOF";

 ##################
 # ascii secsify listifcation perilification transfication of test_data4
 # 
 
EOF

demo( "secsify\(\ listify\(perlify\(\ transify\(\$test_data4\ \)\)\)\ \)", # typed in command           
      secsify( listify(perlify( transify($test_data4 ))) )); # execution


print << "EOF";

 ##################
 # ascii secsify listifcation perilification transfication of test_data5
 # 
 
EOF

demo( "secsify\(\ listify\(perlify\(\ transify\(\$test_data5\)\)\)\ \)", # typed in command           
      secsify( listify(perlify( transify($test_data5))) )); # execution


print << "EOF";

 ##################
 # binary secsify an array reference
 # 
 
EOF

demo( "unpack\(\'H\*\'\,secsify\(\ listify\(\ \[\'2\'\,\ \'hello\'\,\ 4\]\ \)\,\ \{type\ \=\>\ \'binary\'\}\)\)", # typed in command           
      unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary'}))); # execution


print << "EOF";

 ##################
 # binary secsify numeric arrays
 # 
 
EOF

demo( "unpack\(\'H\*\'\,secsify\(\ listify\(\ \$test_data6\ \)\,\ \[type\ \=\>\ \'binary\'\]\)\)", # typed in command           
      unpack('H*',secsify( listify( $test_data6 ), [type => 'binary']))); # execution


print << "EOF";

 ##################
 # scalar binary secsify an array reference
 # 
 
EOF

demo( "unpack\(\'H\*\'\,secsify\(\ listify\(\ \[\'2\'\,\ \'hello\'\,\ 4\]\ \)\,\ \{type\ \=\>\ \'binary\'\,\ scalar\ \=\>\ 1\}\)\)", # typed in command           
      unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary', scalar => 1}))); # execution


print << "EOF";

 ##################
 # scalar binary secsify numeric arrays
 # 
 
EOF

demo( "unpack\(\'H\*\'\,secsify\(\ listify\(\ \$test_data6\ \)\,\ type\ \=\>\ \'binary\'\,\ scalar\ \=\>\ 1\)\)", # typed in command           
      unpack('H*',secsify( listify( $test_data6 ), type => 'binary', scalar => 1))); # execution


print << "EOF";

 ##################
 # binary secsify array with nested hashes, arrays, objects
 # 
 
EOF

demo( "\$big_secs2\ \=\ \
\'a501\'\ \.\ \'50\'\ \.\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \#\ U1\[1\]\ 80\ \ Perl\ format\ code\ \
\'a501\'\ \.\ \'02\'\ \.\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \#\ U1\[1\]\ 2\
\'0106\'\ \.\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \#\ L\[6\]\
\'4100\'\ \.\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \#\ \ \ A\[0\]\
\'4104\'\ \.\ unpack\(\'H\*\'\,\'HASH\'\)\ \.\ \ \ \ \ \ \ \ \#\ \ \ A\[4\]\ HASH\
\'4106\'\ \.\ unpack\(\'H\*\'\,\'header\'\)\ \.\ \ \ \ \ \ \#\ \ \ A\[6\]\ header\
\'0106\'\ \.\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \#\ \ \ L\[6\]\
\'410b\'\ \.\ unpack\(\'H\*\'\,\'Class\:\:None\'\)\ \.\ \#\ \ \ \ \ A\[11\]\ Class\:\:None\
\'4104\'\ \.\ unpack\(\'H\*\'\,\'HASH\'\)\ \.\ \ \ \ \ \ \ \ \#\ \ \ \ \ A\[4\]\ HASH\
\'4104\'\ \.\ unpack\(\'H\*\'\,\'From\'\)\ \.\ \ \ \ \ \ \ \ \#\ \ \ \ \ A\[4\]\ From\
\'4106\'\ \.\ unpack\(\'H\*\'\,\'nobody\'\)\ \.\ \ \ \ \ \ \#\ \ \ \ \ A\[6\]\ nobody\
\'4102\'\ \.\ unpack\(\'H\*\'\,\'To\'\)\ \.\ \ \ \ \ \ \ \ \ \ \#\ \ \ \ \ A\[2\]\ To\
\'4106\'\ \.\ unpack\(\'H\*\'\,\'nobody\'\)\ \.\ \ \ \ \ \ \#\ \ \ \ \ A\[6\]\ nobody\
\'4103\'\ \.\ unpack\(\'H\*\'\,\'msg\'\)\ \.\ \ \ \ \ \ \ \ \ \#\ \ \ A\[3\]\ msg\
\'0104\'\ \.\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \#\ \ \ L\[4\]\
\'4100\'\ \.\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \#\ \ \ \ \ A\[0\]\
\'4105\'\ \.\ unpack\(\'H\*\'\,\'ARRAY\'\)\ \.\ \ \ \ \ \ \ \#\ \ \ \ \ A\[5\]\ ARRAY\
\'4105\'\ \.\ unpack\(\'H\*\'\,\'hello\'\)\ \.\ \ \ \ \ \ \ \#\ \ \ \ \ A\[5\]\ hello\ \
\'4105\'\ \.\ unpack\(\'H\*\'\,\'world\'\)\;\ \ \ \ \ \ \ \ \#\ \ \ \ \ A\[5\]\ world"); # typed in command           
      $big_secs2 = 
'a501' . '50' .                       # U1[1] 80  Perl format code 
'a501' . '02' .                       # U1[1] 2
'0106' .                              # L[6]
'4100' .                              #   A[0]
'4104' . unpack('H*','HASH') .        #   A[4] HASH
'4106' . unpack('H*','header') .      #   A[6] header
'0106' .                              #   L[6]
'410b' . unpack('H*','Class::None') . #     A[11] Class::None
'4104' . unpack('H*','HASH') .        #     A[4] HASH
'4104' . unpack('H*','From') .        #     A[4] From
'4106' . unpack('H*','nobody') .      #     A[6] nobody
'4102' . unpack('H*','To') .          #     A[2] To
'4106' . unpack('H*','nobody') .      #     A[6] nobody
'4103' . unpack('H*','msg') .         #   A[3] msg
'0104' .                              #   L[4]
'4100' .                              #     A[0]
'4105' . unpack('H*','ARRAY') .       #     A[5] ARRAY
'4105' . unpack('H*','hello') .       #     A[5] hello 
'4105' . unpack('H*','world');        #     A[5] world; # execution

print << "EOF";

 ##################
 # neuterify a big secsii
 # 
 
EOF

demo( "secsify\(neuterify\ \(pack\(\'H\*\'\,\$big_secs2\)\)\)", # typed in command           
      secsify(neuterify (pack('H*',$big_secs2)))); # execution


print << "EOF";

 ##################
 # neuterify binary secsii
 # 
 
EOF

demo( "secsify\(neuterify\ \(pack\(\'H\*\'\,\$test_data7\)\)\)", # typed in command           
      secsify(neuterify (pack('H*',$test_data7)))); # execution


print << "EOF";

 ##################
 # neuterify scalar binary secsii, length size error
 # 
 
EOF

demo( "\ \ \ \$event\ \=\ neuterify\ \(pack\(\'H\*\'\,\$test_data17\)\)\;\
\ \ \ \$event\ \=\~\ s\/\\n\\t\.\*\?\$\/\/\;\
\ \ \ while\(chomp\(\$event\)\)\ \{\ \}\;"); # typed in command           
         $event = neuterify (pack('H*',$test_data17));
   $event =~ s/\n\t.*?$//;
   while(chomp($event)) { };; # execution

demo( "\$event", # typed in command           
      $event); # execution


print << "EOF";

 ##################
 # neuterify scalar binary secsii, no error
 # 
 
EOF

demo( "\$event\ \=\ neuterify\ \(pack\(\'H\*\'\,\$test_data17\)\,\ scalar\ \=\>\ 1\)"); # typed in command           
      $event = neuterify (pack('H*',$test_data17), scalar => 1); # execution

demo( "ref\(\$event\)", # typed in command           
      ref($event)); # execution


print << "EOF";

 ##################
 # neuterify scalar binary secsii
 # 
 
EOF

demo( "secsify\(\$event\)", # typed in command           
      secsify($event)); # execution


print << "EOF";

 ##################
 # transify a free for all secsii input
 # 
 
EOF

demo( "\ \ \ \ my\ \$ascii_secsii\ \=\
\'\
L\
\(\
\ \ A\ \\\'\\\'\ A\ \\\'HASH\\\'\ A\ \\\'header\\\'\
\ \ L\ \[\ A\ \"Class\:\:None\"\ \ A\ \"HASH\"\ \
\ \ \ \ \ \ A\ \ \"From\"\ A\ \"nobody\"\
\ \ \ \ \ \ A\ \ \"To\"\ A\ \"nobody\"\
\ \ \ \ \]\
\ \ A\ \"msg\"\
\ \ L\,4\ A\[0\]\ A\[5\]\ ARRAY\
\ \ \ \ A\ \ \"hello\"\ A\ \"world\"\
\)\
\
L\ \
\(\
\ \ A\[0\]\ A\ \"HASH\"\ \ A\ \/header\/\
\ \ L\[3\]\ A\[0\]\ A\ \\\'Index\\\'\ U1\ 10\
\ \ A\ \ \\\'msg\\\'\
\ \ L\ \<\ A\[0\]\ A\ \\\'ARRAY\\\'\ A\ \ \\\'body\\\'\ \>\
\)\
\
\'"); # typed in command           
          my $ascii_secsii =
'
L
(
  A \'\' A \'HASH\' A \'header\'
  L [ A "Class::None"  A "HASH" 
      A  "From" A "nobody"
      A  "To" A "nobody"
    ]
  A "msg"
  L,4 A[0] A[5] ARRAY
    A  "hello" A "world"
)

L 
(
  A[0] A "HASH"  A /header/
  L[3] A[0] A \'Index\' U1 10
  A  \'msg\'
  L < A[0] A \'ARRAY\' A  \'body\' >
)

'; # execution

demo( "my\ \$list\ \=\ transify\ \(\$ascii_secsii\,\ obj_format_code\ \=\>\ \'P\'\)\;"); # typed in command           
      my $list = transify ($ascii_secsii, obj_format_code => 'P');; # execution

demo( "ref\(\$list\)", # typed in command           
      ref($list)); # execution


print << "EOF";

 ##################
 # secsify transified free style secs text
 # 
 
EOF

demo( "ref\(\$list\)\ \?\ secsify\(\ \$list\ \)\ \:\ \'\'", # typed in command           
      ref($list) ? secsify( $list ) : ''); # execution


print << "EOF";

 ##################
 # transify a bad free for all secsii input
 # 
 
EOF

demo( "\ \ \ \ \$ascii_secsii\ \=\
\'\
L\
\(\ \
\ \ A\ \"msg\"\
\ \ L\,4\ A\[0\]\ A\[5\]\ world\
\'"); # typed in command           
          $ascii_secsii =
'
L
( 
  A "msg"
  L,4 A[0] A[5] world
'; # execution

demo( "\$list\ \=\ transify\ \(\$ascii_secsii\)\;"); # typed in command           
      $list = transify ($ascii_secsii);; # execution

demo( "ref\(\\\$list\)", # typed in command           
      ref(\$list)); # execution


demo( "\$list", # typed in command           
      $list); # execution


print << "EOF";

 ##################
 # Perl listify numeric arrays
 # 
 
EOF

demo( "ref\(my\ \$number_list\ \=\ Data\:\:Secs2\-\>new\(perl_secs_numbers\ \=\>\ \'strict\'\)\-\>listify\(\ \$test_data6\ \)\)", # typed in command           
      ref(my $number_list = Data::Secs2->new(perl_secs_numbers => 'strict')->listify( $test_data6 ))); # execution


print << "EOF";

 ##################
 # secify Perl  listified numberic arrays
 # 
 
EOF

demo( "secsify\(\$number_list\)", # typed in command           
      secsify($number_list)); # execution


print << "EOF";

 ##################
 # read configuration
 # 
 
EOF

demo( "\[config\(\'type\'\)\]", # typed in command           
      [config('type')]); # execution


print << "EOF";

 ##################
 # write configuration
 # 
 
EOF

demo( "\[config\(\'type\'\,\'binary\'\)\]", # typed in command           
      [config('type','binary')]); # execution


print << "EOF";

 ##################
 # verify write configuration
 # 
 
EOF

demo( "\[config\(\'type\'\)\]", # typed in command           
      [config('type')]); # execution


print << "EOF";

 ##################
 # restore configuration
 # 
 
EOF

demo( "\[config\(\'type\'\,\'ascii\'\)\]", # typed in command           
      [config('type','ascii')]); # execution



=head1 NAME

Secs2.d - demostration script for Data::Secs2

=head1 SYNOPSIS

 Secs2.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

## end of test script file ##

=cut

