# t/004_ord2alt.t - verify that alternate names are returned correctlu
#
# $Id: 004_ord2alt.t,v 1.1 2004/02/18 13:56:28 coar Exp $
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

my $res;
my $fallthrough = 1;
my %altnames = (
                0x09 => 'TAB',
                0x11 => 'XON',
                0x13 => 'XOFF',
                0x20 => 'SP',
                0x00 => 'NUL',  # Not an alternate name, so should fall through
                                # to the regular name
                0x2a => chr(0x2a), # Not a special character
               );
plan(tests => 512);
Convert::ASCIInames::Configure(fallthrough => $fallthrough);
runem();
$fallthrough = 0;
Convert::ASCIInames::Configure(fallthrough => $fallthrough);
$altnames{0x00} = chr(0x00);
runem();

sub runem {
    for (my $ord = 0; $ord < 256; $ord++) {
        my $expected = (defined($altnames{$ord})
                        ? $altnames{$ord}
                        : ($fallthrough
                           ? ASCIIname($ord)
                           : chr($ord)));
        $res = ASCIIaltname($ord);
        ok($res eq $expected, "ASCIIaltname($ord) == '$expected'; got '$res'");
    }
}
__END__

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# End:
#
