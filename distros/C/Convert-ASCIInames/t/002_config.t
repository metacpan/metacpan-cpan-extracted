# t/002_config.t - verify that options configuration is working
#
# $Id: 002_config.t,v 1.1 2004/02/18 13:56:28 coar Exp $
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

use Test::More(tests => 5);
use Convert::ASCIInames;

my $rconfig;
my $fallthrough;

#
# Verify that the default is fallthrough=>1
#
$rconfig = Convert::ASCIInames::Configure();
$fallthrough = $rconfig->{fallthrough};
ok($fallthrough == 1, "Default 'fallthrough' == 1; got '$fallthrough'");

#
# Set it to zero; answer should be one (last setting).
#
$rconfig = Convert::ASCIInames::Configure(fallthrough => 0);
$fallthrough = $rconfig->{fallthrough};
ok($fallthrough == 1, "Default 'fallthrough' == 1; got '$fallthrough'");

#
# Now reset it to 1; previous value should be zero.
#
$rconfig = Convert::ASCIInames::Configure(fallthrough => 1);
$fallthrough = $rconfig->{fallthrough};
ok($fallthrough == 0, "Current 'fallthrough' == 0; got '$fallthrough'");

#
# Verify that the last setting stuck.
#
$rconfig = Convert::ASCIInames::Configure();
$fallthrough = $rconfig->{fallthrough};
ok($fallthrough == 1, "Default 'fallthrough' == 1; got '$fallthrough'");

#
# Verify that it properly handles a hashref.
#
Convert::ASCIInames::Configure({fallthrough => 0});
$rconfig = Convert::ASCIInames::Configure();
$fallthrough = $rconfig->{fallthrough};
ok($fallthrough == 0, "Hashref 'fallthrough' == 0; got '$fallthrough'");

__END__

#
# Local Variables:
# mode: cperl
# tab-width: 4
# indent-tabs-mode: nil
# End:
#
