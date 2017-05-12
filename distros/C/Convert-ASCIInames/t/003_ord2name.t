# t/003_ord2name.t - verify that primary names are returned correctly
#
# $Id: 003_ord2name.t,v 1.1 2004/02/18 13:56:28 coar Exp $
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
my %names = (
             0x00 => 'NUL',
             0x01 => 'SOH',
             0x02 => 'STX',
             0x03 => 'ETX',
             0x04 => 'EOT',
             0x05 => 'ENQ',
             0x06 => 'ACK',
             0x07 => 'BEL',
             0x08 => 'BS',
             0x09 => 'HT',
             0x0a => 'LF',
             0x0b => 'VT',
             0x0c => 'FF',
             0x0d => 'CR',
             0x0e => 'SO',
             0x0f => 'SI',
             0x10 => 'DLE',
             0x11 => 'DC1',
             0x12 => 'DC2',
             0x13 => 'DC3',
             0x14 => 'DC4',
             0x15 => 'NAK',
             0x16 => 'SYN',
             0x17 => 'ETB',
             0x18 => 'CAN',
             0x19 => 'EM',
             0x1a => 'SUB',
             0x1b => 'ESC',
             0x1c => 'FS',
             0x1d => 'GS',
             0x1e => 'RS',
             0x1f => 'US',
             0x7f => 'DEL',
             0x80 => 'RES1',
             0x81 => 'RES2',
             0x82 => 'RES3',
             0x83 => 'RES4',
             0x84 => 'IND',
             0x85 => 'NEL',
             0x86 => 'SSA',
             0x87 => 'ESA',
             0x88 => 'HTS',
             0x89 => 'HTJ',
             0x8a => 'VTS',
             0x8b => 'PLD',
             0x8c => 'PLU',
             0x8d => 'RI',
             0x8e => 'SS2',
             0x8f => 'SS3',
             0x90 => 'DCS',
             0x91 => 'PU1',
             0x92 => 'PU2',
             0x93 => 'STS',
             0x94 => 'CCH',
             0x95 => 'MW',
             0x96 => 'SPA',
             0x97 => 'EPA',
             0x98 => 'RES5',
             0x99 => 'RES6',
             0x9a => 'RES7',
             0x9b => 'CSI',
             0x9c => 'ST',
             0x9d => 'OSC',
             0x9e => 'PM',
             0x9f => 'APC',
             0x63 => chr(0x63), # Not a special character, fail to actual
            );

plan(tests => 512);
Convert::ASCIInames::Configure(fallthrough => 0);
runem();
Convert::ASCIInames::Configure(fallthrough => 1);
$names{0x20} = 'SP';
runem();

sub runem {
    for (my $ord = 0; $ord < 256; $ord++) {
        my $expected = (defined($names{$ord}) ? $names{$ord} : chr($ord));
        $res = ASCIIname($ord);
        ok($res eq $expected, "ASCIIname($ord) == '$expected'; got '$res'");
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
