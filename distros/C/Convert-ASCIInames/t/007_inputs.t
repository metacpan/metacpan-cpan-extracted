# t/007_inputs.t - verify that input conditions are checked properly
#
# $Id: 007_inputs.t,v 1.1 2004/02/18 13:56:28 coar Exp $
#
#   CPAN module Convert::ASCIInames
#
#   Copyright 2004 Ken A L Coar
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this package or any files in it except in
#   compliance with the License.  A copy of the License should be
#   included as part of the package; the normative version may be
#   obtained a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

use Test::More;
use Convert::ASCIInames;
use Carp;

my $res;
my $msg;

#
# Trap the carp() messages for examination.
#
$SIG{__WARN__} = sub {
    $msg = $_[0];
};

plan(tests => 9);

Convert::ASCIInames::Configure(strict_ordinals => 1);

$msg = undef;
$res = ASCIIname();
ok($msg =~ /^Null ordinal; using 0x00 at /, "ASCIIname() raised '$msg'");

$msg = undef;
$res = ASCIIname('');
ok($msg =~ /^Null ordinal; using 0x00 at /,  "ASCIIname('') raised '$msg'");

$msg = undef;
$res = ASCIIname('+23');
ok((! defined($msg)), "ASCIIname('+23') raised '$msg'");

$msg = undef;
$res = ASCIIname('-23');
ok($msg =~ /^\QIllegal ordinal value (< 0 or > 255); using 255\E/,
   "ASCIIname('-23') raised '$msg'");

$msg = undef;
$res = ASCIIname('foo');
ok($msg =~ /^Ordinal is not a positive integer; converting the first character at /,
   "ASCIIname('foo') raised '$msg'");

$msg = undef;
$res = ASCIIname(32767);
ok($msg =~ /^\QIllegal ordinal value (< 0 or > 255); using 255\E/,
   "ASCIIname(32767) raised '$msg'");

$msg = undef;
$res = ASCIIordinal();
ok($msg =~ /^Null character; using NUL/, "ASCIIordinal() raised '$msg'");

$msg = undef;
$res = ASCIIordinal('');
ok($msg =~ /^Null character; using NUL/, "ASCIIordinal('') raised '$msg'");

Convert::ASCIInames::Configure(strict_ordinals => 0);

$msg = undef;
$res = ASCIIname('foo');
ok((! defined($msg)), "ASCIIname('foo') raised '$msg'");


__END__

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# End:
#
