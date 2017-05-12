#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Data::Str2Num;

use strict;
use 5.001;
use warnings;
use warnings::register;

#####
# Connect up with the event log.
#
use vars qw( $VERSION $DATE $FILE);
$VERSION = '0.02';
$DATE = '2003/08/04';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(&str2int);


######
# Convert number (oct, bin, hex, decimal) to decimal
#
sub str2int
{
    return undef unless(defined($_[0]));      
    shift @_ if $_[0] eq 'Data::Str2Num' || ref($_[0]);  # drop self on object call 
    my ($num) = @_;
    return undef unless defined($num);
    return 0+oct($num) if( $num =~ /^0[0-7]+$|^0b[0-1]+$|^0x[0-9A-Fa-f]+$/ ); 
    return 0+$num if( $num =~ /^[ 0-9]+$/ ); 
    undef;

}

1

__END__


=head1 NAME

Data::Str2int - convert a scalar string to an integer

=head1 SYNOPSIS

 use Data::Str2Num;

 $integer = Data::Str2Num->str2int($str)


 use Data::Str2Num qw(str2int);

 $integer = str2int($str)

=head1 DESCRIPTION

The "Data::Str2Num" module translates an scalar string to a scalar integer.
Perl itself has a documented function, '0+$x', that converts a scalar to
so that its internal storage is an integer
(See p.351, 3rd Edition of Programming Perl).
If it cannot perform the conversion, it leaves the integer 0.
Surprising not all Perls, some Microsoft Perls in particular, may leave
the internal storage as a scalar string.

The "str2int" function is basically the same except if it cannot perform
the conversion to an integer, it returns an "undef" instead of a 0.
Also, if the string is a decimal or floating point, it will return an undef.
This makes it not only useful for forcing an integer conversion but
also for testing a scalar to see if it is in fact an integer scalar.

=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Package;
 =>     my $fp = 'File::Package';

 =>     my $s2n = 'Data::Str2Num';
 =>     my $loaded;
 => my $errors = $fp->load_package($s2n)
 => $errors
 ''

 => $s2n->str2int('033')
 '27'

 => $s2n->str2int('0xFF')
 '255'

 => $s2n->str2int('0b1010')
 '10'

 => $s2n->str2int('255')
 '255'

 => $s2n->str2int('hello')
 undef


=head1 QUALITY ASSURANCE

The module "t::Data::Str2Num" is the Software
Test Description(STD) module for the "Data::Str2Num".
module. 

To generate all the test output files, 
run the generated test script,
run the demonstration script and include it results in the "Data::Str2Num" POD,
execute the following in any directory:

 tmake -test_verbose -replace -run  -pm=t::Data::Str2Num

Note that F<tmake.pl> must be in the execution path C<$ENV{PATH}>
and the "t" directory containing  "t::Data::Str2Num" on the same level as the "lib" 
directory that contains the "Data::Str2Num" module.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, 490A (L<STD490A/3.2.3.6>).
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
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

=head2 SEE_ALSO:

=over 4

=item L<File::Spec|File::Spec>

=item L<Data::Str2Num|Data::Str2Num>

=back

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut
### end of script  ######