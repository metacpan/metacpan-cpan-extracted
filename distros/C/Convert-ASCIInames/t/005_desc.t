# t/005_desc.t - verify that primary descriptions are returned correctly
#
# $Id: 005_desc.t,v 1.1 2004/02/18 13:56:28 coar Exp $
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
my %descs = (
             0x00 => 'Null character',
             0x01 => 'Start of Header',
             0x02 => 'Start of Text',
             0x03 => 'End Of Text',
             0x04 => 'End Of Transmission',
             0x05 => 'Enquiry',
             0x06 => 'Acknowledge',
             0x07 => 'Bell',
             0x08 => 'Backspace',
             0x09 => 'Horizontal Tab',
             0x0a => 'Linefeed',
             0x0b => 'Vertical Tab',
             0x0c => 'Formfeed',
             0x0d => 'Carriage Return',
             0x0e => 'Shift Out',
             0x0f => 'Shift In',
             0x10 => 'Data Link Escape',
             0x11 => 'Device Control 1',
             0x12 => 'Device Control 2',
             0x13 => 'Device Control 3',
             0x14 => 'Device Control 4',
             0x15 => 'Negative Acknowledge',
             0x16 => 'Synchronous Idle',
             0x17 => 'End of Transmission Block',
             0x18 => 'Cancel',
             0x19 => 'End of Medium',
             0x1a => 'Substitute',
             0x1b => 'Escape',
             0x1c => 'File Separator',
             0x1d => 'Group Separator',
             0x1e => 'Record Separator',
             0x1f => 'Unit Separator',
             0x7f => 'Delete',
             0x80 => 'Reserved for future standardizaton',
             0x81 => 'Reserved for future standardizaton',
             0x82 => 'Reserved for future standardizaton',
             0x83 => 'Reserved for future standardizaton',
             0x84 => 'Index',
             0x85 => 'Next Line',
             0x86 => 'Start of Selected Area',
             0x87 => 'End of Selected Area',
             0x88 => 'Horizontal Tabulation Set',
             0x89 => 'Horizontal Tab with Justify',
             0x8a => 'Vertical Tabulation Set',
             0x8b => 'Partial Line Down',
             0x8c => 'Partial Line Up',
             0x8d => 'Reverse Index',
             0x8e => 'Single Shift 2',
             0x8f => 'Single Shift 3',
             0x90 => 'Device control string',
             0x91 => 'Private Use 1',
             0x92 => 'Private Use 2',
             0x93 => 'Set Transmission State',
             0x94 => 'Cancel Character',
             0x95 => 'Message Waiting',
             0x96 => 'Start of Protected Area',
             0x97 => 'End of Protected Area',
             0x98 => 'Reserved for future standardization',
             0x99 => 'Reserved for future standardization',
             0x9a => 'Reserved for future standardization',
             0x9b => 'Control Sequence Introducer',
             0x9c => 'String Terminator',
             0x9d => 'Operating System Command',
             0x9e => 'Privacy Message',
             0x9f => 'Application Program Command',
             0x41 => chr(0x41),   # Not a special character
            );

Convert::ASCIInames::Configure(fallthrough => 0);
plan(tests => 512);
runem();
Convert::ASCIInames::Configure(fallthrough => 1);
$descs{0x20} = 'Space';
runem();

sub runem {
    for (my $ord = 0; $ord < 256; $ord++) {
        my $expected = (defined($descs{$ord}) ? $descs{$ord} : chr($ord));
        $res = ASCIIdescription($ord);
        ok($res eq $expected,
           "ASCIIdescription($ord) == '$expected'; got '$res'");
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
