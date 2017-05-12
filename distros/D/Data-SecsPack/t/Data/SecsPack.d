#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.04';   # automatically generated file
$DATE = '2004/05/10';


##### Demonstration Script ####
#
# Name: SecsPack.d
#
# UUT: Data::SecsPack
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Data::SecsPack 
#
# Don't edit this test script file, edit instead
#
# t::Data::SecsPack
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
\ \ \ \ my\ \$uut\ \=\ \'Data\:\:SecsPack\'\;\
\ \ \ \ my\ \$loaded\;\
\
\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ Provide\ a\ scalar\ or\ array\ context\.\
\ \ \ \ \#\
\ \ \ \ my\ \(\$result\,\@result\)\;"); # typed in command           
          use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Data::SecsPack';
    my $loaded;

    #####
    # Provide a scalar or array context.
    #
    my ($result,@result);; # execution

print << "EOF";

 ##################
 # UUT Loaded
 # 
 
EOF

demo( "\ \ \ my\ \$errors\ \=\ \$fp\-\>load_package\(\$uut\,\ \
\ \ \ \ \ \ \ qw\(bytes2int\ float2binary\ \
\ \ \ \ \ \ \ \ \ \ ifloat2binary\ int2bytes\ \ \ \
\ \ \ \ \ \ \ \ \ \ pack_float\ pack_int\ pack_num\ \ \
\ \ \ \ \ \ \ \ \ \ str2float\ str2int\ \
\ \ \ \ \ \ \ \ \ \ unpack_float\ unpack_int\ unpack_num\)\ \)\;"); # typed in command           
         my $errors = $fp->load_package($uut, 
       qw(bytes2int float2binary 
          ifloat2binary int2bytes   
          pack_float pack_int pack_num  
          str2float str2int 
          unpack_float unpack_int unpack_num) );; # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

print << "EOF";

 ##################
 # str2int(\'0xFF\')
 # 
 
EOF

demo( "\$result\ \=\ \$uut\-\>str2int\(\'0xFF\'\)", # typed in command           
      $result = $uut->str2int('0xFF')); # execution


print << "EOF";

 ##################
 # str2int(\'255\')
 # 
 
EOF

demo( "\$result\ \=\ \$uut\-\>str2int\(\'255\'\)", # typed in command           
      $result = $uut->str2int('255')); # execution


print << "EOF";

 ##################
 # str2int(\'hello\')
 # 
 
EOF

demo( "\$result\ \=\ \$uut\-\>str2int\(\'hello\'\)", # typed in command           
      $result = $uut->str2int('hello')); # execution


print << "EOF";

 ##################
 # str2int(1E20)
 # 
 
EOF

demo( "\$result\ \=\ \$uut\-\>str2int\(1E20\)", # typed in command           
      $result = $uut->str2int(1E20)); # execution


print << "EOF";

 ##################
 # str2int(' 78 45 25', ' 512E4 1024 hello world') \@numbers
 # 
 
EOF

demo( "my\ \(\$strings\,\ \@numbers\)\ \=\ str2int\(\'\ 78\ 45\ 25\'\,\ \'\ 512E4\ 1024\ hello\ world\'\)"); # typed in command           
      my ($strings, @numbers) = str2int(' 78 45 25', ' 512E4 1024 hello world'); # execution

demo( "\[\@numbers\]", # typed in command           
      [@numbers]); # execution


print << "EOF";

 ##################
 # str2int(' 78 45 25', ' 512E4 1024 hello world') \@strings
 # 
 
EOF

demo( "join\(\ \'\ \'\,\ \@\$strings\)", # typed in command           
      join( ' ', @$strings)); # execution


print << "EOF";

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') numbers
 # 
 
EOF

demo( "\(\$strings\,\ \@numbers\)\ \=\ str2float\(\'\ 78\ \-2\.4E\-6\ 0\.0025\ \ 0\'\,\ \'\ 512E4\ hello\ world\'\)"); # typed in command           
      ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025  0', ' 512E4 hello world'); # execution

demo( "\[\@numbers\]", # typed in command           
      [@numbers]); # execution


print << "EOF";

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') \@strings
 # 
 
EOF

demo( "join\(\ \'\ \'\,\ \@\$strings\)", # typed in command           
      join( ' ', @$strings)); # execution


print << "EOF";

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) numbers
 # 
 
EOF

demo( "\(\$strings\,\ \@numbers\)\ \=\ str2float\(\'\ 78\ \-2\.4E\-6\ 0\.0025\ 0xFF\ 077\ 0\'\,\ \'\ 512E4\ hello\ world\'\,\ \{ascii_float\ \=\>\ 1\}\)"); # typed in command           
      ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}); # execution

demo( "\[\@numbers\]", # typed in command           
      [@numbers]); # execution


print << "EOF";

 ##################
 # str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) \@strings
 # 
 
EOF

demo( "join\(\ \'\ \'\,\ \@\$strings\)", # typed in command           
      join( ' ', @$strings)); # execution


demo( "\ \ \ \ \ my\ \@test_strings\ \=\ \(\'78\ 45\ 25\'\,\ \'512\ 1024\ 100000\ hello\ world\'\)\;\
\ \ \ \ \ my\ \$test_string_text\ \=\ join\ \'\ \'\,\@test_strings\;\
\ \ \ \ \ my\ \$test_format\ \=\ \'I\'\;\
\ \ \ \ \ my\ \$expected_format\ \=\ \'U4\'\;\
\ \ \ \ \ my\ \$expected_numbers\ \=\ \'0000004e0000002d000000190000020000000400000186a0\'\;\
\ \ \ \ \ my\ \$expected_strings\ \=\ \[\'hello\ world\'\]\;\
\ \ \ \ \ my\ \$expected_unpack\ \=\ \[78\,\ 45\,\ 25\,\ 512\,\ 1024\,\ 100000\]\;\
\
\ \ \ \ \ my\ \(\$format\,\ \$numbers\,\ \@strings\)\ \=\ pack_num\(\'I\'\,\@test_strings\)\;"); # typed in command           
           my @test_strings = ('78 45 25', '512 1024 100000 hello world');
     my $test_string_text = join ' ',@test_strings;
     my $test_format = 'I';
     my $expected_format = 'U4';
     my $expected_numbers = '0000004e0000002d000000190000020000000400000186a0';
     my $expected_strings = ['hello world'];
     my $expected_unpack = [78, 45, 25, 512, 1024, 100000];

     my ($format, $numbers, @strings) = pack_num('I',@test_strings);; # execution

print << "EOF";

 ##################
 # pack_num($test_format, $test_string_text) format
 # 
 
EOF

demo( "\$format", # typed in command           
      $format); # execution


print << "EOF";

 ##################
 # pack_num($test_format, $test_string_text) numbers
 # 
 
EOF

demo( "unpack\(\'H\*\'\,\$numbers\)", # typed in command           
      unpack('H*',$numbers)); # execution


print << "EOF";

 ##################
 # pack_num($test_format, $test_string_text) \@strings
 # 
 
EOF

demo( "\[\@strings\]", # typed in command           
      [@strings]); # execution


print << "EOF";

 ##################
 # unpack_num($expected_format, $test_string_text) error check
 # 
 
EOF

demo( "ref\(my\ \$unpack_numbers\ \=\ unpack_num\(\$expected_format\,\$numbers\)\)", # typed in command           
      ref(my $unpack_numbers = unpack_num($expected_format,$numbers))); # execution


print << "EOF";

 ##################
 # unpack_num($expected_format, $test_string_text) numbers
 # 
 
EOF

demo( "\$unpack_numbers", # typed in command           
      $unpack_numbers); # execution


demo( "\ \
\ \ \ \ \ \@test_strings\ \=\ \(\'78\ 4\.5\ \.25\'\,\ \'6\.45E10\ hello\ world\'\)\;\
\ \ \ \ \ \$test_string_text\ \=\ join\ \'\ \'\,\@test_strings\;\
\ \ \ \ \ \$test_format\ \=\ \'I\'\;\
\ \ \ \ \ \$expected_format\ \=\ \'F8\'\;\
\ \ \ \ \ \$expected_numbers\ \=\ \'405380000000000040120000000000003fd0000000000000422e08ffca000000\'\;\
\ \ \ \ \ \$expected_strings\ \=\ \[\'hello\ world\'\]\;\
\ \ \ \ \ my\ \@expected_unpack\ \=\ \(\
\ \ \ \ \ \ \ \ \ \ \'7\.800000000000017486E1\'\,\ \
\ \ \ \ \ \ \ \ \ \ \'4\.500000000000006245E0\'\,\
\ \ \ \ \ \ \ \ \ \ \'2\.5E\-1\'\,\
\ \ \ \ \ \ \ \ \ \ \'6\.4500000000000376452E10\'\
\ \ \ \ \ \)\;\
\
\ \ \ \ \ \(\$format\,\ \$numbers\,\ \@strings\)\ \=\ pack_num\(\'I\'\,\@test_strings\)\;"); # typed in command           
       
     @test_strings = ('78 4.5 .25', '6.45E10 hello world');
     $test_string_text = join ' ',@test_strings;
     $test_format = 'I';
     $expected_format = 'F8';
     $expected_numbers = '405380000000000040120000000000003fd0000000000000422e08ffca000000';
     $expected_strings = ['hello world'];
     my @expected_unpack = (
          '7.800000000000017486E1', 
          '4.500000000000006245E0',
          '2.5E-1',
          '6.4500000000000376452E10'
     );

     ($format, $numbers, @strings) = pack_num('I',@test_strings);; # execution

print << "EOF";

 ##################
 # pack_num($test_format, $test_string_text) format
 # 
 
EOF

demo( "\$format", # typed in command           
      $format); # execution


print << "EOF";

 ##################
 # pack_num($test_format, $test_string_text) numbers
 # 
 
EOF

demo( "unpack\(\'H\*\'\,\$numbers\)", # typed in command           
      unpack('H*',$numbers)); # execution


print << "EOF";

 ##################
 # pack_num($test_format, $test_string_text) \@strings
 # 
 
EOF

demo( "\[\@strings\]", # typed in command           
      [@strings]); # execution


print << "EOF";

 ##################
 # unpack_num($expected_format, $test_string_text) error check
 # 
 
EOF

demo( "ref\(\$unpack_numbers\ \=\ unpack_num\(\$expected_format\,\$numbers\)\)", # typed in command           
      ref($unpack_numbers = unpack_num($expected_format,$numbers))); # execution


print << "EOF";

 ##################
 # unpack_num($expected_format, $test_string_text) numbers
 # 
 
EOF

demo( "\$unpack_numbers", # typed in command           
      $unpack_numbers); # execution



=head1 NAME

SecsPack.d - demostration script for Data::SecsPack

=head1 SYNOPSIS

 SecsPack.d

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

