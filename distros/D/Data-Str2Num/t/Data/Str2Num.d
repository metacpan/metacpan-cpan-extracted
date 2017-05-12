#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.03';   # automatically generated file
$DATE = '2004/05/19';


##### Demonstration Script ####
#
# Name: Str2Num.d
#
# UUT: Data::Str2Num
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Data::Str2Num 
#
# Don't edit this test script file, edit instead
#
# t::Data::Str2Num
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

    ########
    # Using Test::Tech, a very light layer over the module "Test" to
    # conduct the tests.  The big feature of the "Test::Tech: module
    # is that it takes expected and actual references and stringify
    # them by using "Data::Secs2" before passing them to the "&Test::ok"
    # Thus, almost any time of Perl data structures may be
    # compared by passing a reference to them to Test::Tech::ok
    #
    # Create the test plan by supplying the number of tests
    # and the todo tests
    #
    require Test::Tech;
    Test::Tech->import( qw(demo finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );

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
\ \ \ \ my\ \$uut\ \=\ \'Data\:\:Str2Num\'\;\
\ \ \ \ my\ \$loaded\;\
\ \ \ \ my\ \(\$result\,\@result\)\;\ \#\ force\ a\ context"); # typed in command           
          use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Data::Str2Num';
    my $loaded;
    my ($result,@result); # force a context; # execution

print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\$uut\,\ \'str2float\'\,\'str2int\'\,\'str2integer\'\,\)"); # typed in command           
      my $errors = $fp->load_package($uut, 'str2float','str2int','str2integer',); # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

print << "EOF";

 ##################
 # str2int(\'033\')
 # 
 
EOF

demo( "\$uut\-\>str2int\(\'033\'\)", # typed in command           
      $uut->str2int('033')); # execution


print << "EOF";

 ##################
 # str2int(\'0xFF\')
 # 
 
EOF

demo( "\$uut\-\>str2int\(\'0xFF\'\)", # typed in command           
      $uut->str2int('0xFF')); # execution


print << "EOF";

 ##################
 # str2int(\'0b1010\')
 # 
 
EOF

demo( "\$uut\-\>str2int\(\'0b1010\'\)", # typed in command           
      $uut->str2int('0b1010')); # execution


print << "EOF";

 ##################
 # str2int(\'255\')
 # 
 
EOF

demo( "\$uut\-\>str2int\(\'255\'\)", # typed in command           
      $uut->str2int('255')); # execution


print << "EOF";

 ##################
 # str2int(\'hello\')
 # 
 
EOF

demo( "\$uut\-\>str2int\(\'hello\'\)", # typed in command           
      $uut->str2int('hello')); # execution


print << "EOF";

 ##################
 # str2integer(1E20)
 # 
 
EOF

demo( "\$result\ \=\ \$uut\-\>str2integer\(1E20\)", # typed in command           
      $result = $uut->str2integer(1E20)); # execution


print << "EOF";

 ##################
 # str2integer(' 78 45 25', ' 512E4 1024 hello world') \@numbers
 # 
 
EOF

demo( "my\ \(\$strings\,\ \@numbers\)\ \=\ str2integer\(\'\ 78\ 45\ 25\'\,\ \'\ 512E4\ 1024\ hello\ world\'\)"); # typed in command           
      my ($strings, @numbers) = str2integer(' 78 45 25', ' 512E4 1024 hello world'); # execution

demo( "\[\@numbers\]", # typed in command           
      [@numbers]); # execution


print << "EOF";

 ##################
 # str2integer(' 78 45 25', ' 512E4 1024 hello world') \@strings
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



=head1 NAME

Str2Num.d - demostration script for Data::Str2Num

=head1 SYNOPSIS

 Str2Num.d

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

