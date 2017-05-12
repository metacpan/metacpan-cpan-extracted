# t/006_altdesc.t - verify that alternate descriptions are returned correctly
#
# $Id: 006_altdesc.t,v 1.1 2004/02/18 13:56:28 coar Exp $
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
             0x09 => 'Horizontal tab',
             0x11 => 'Flow control on',
             0x13 => 'Flow control off',
             0x20 => 'Space',
             0x00 => 'Null character', # Not an alternate, fail to primary
             0x5e => chr(0x5e), # Not a special character, fail to character
            );
plan(tests => scalar(keys(%descs)));
while (my ($ord, $desc) = each(%descs)) {
    $res = ASCIIaltdescription($ord);
    ok($res eq $desc, "ASCIIaltdescription($ord) == '$desc'; got '$res'");
}

__END__

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# End:
#
