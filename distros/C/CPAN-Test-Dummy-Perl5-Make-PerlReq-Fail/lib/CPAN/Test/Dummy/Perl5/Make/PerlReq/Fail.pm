# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under the same terms as Perl itself

package CPAN::Test::Dummy::Perl5::Make::PerlReq::Fail;
use strict;
use vars '$VERSION';
$VERSION = '0.001';
$VERSION = eval $VERSION; ## no critic

require 6; # require Perl 6

1;

__END__

=head1 NAME

CPAN::Test::Dummy::Perl5::Make::PerlReq::Fail - CPAN Test Dummy that fails to find a required version of Perl

=head1 SYNOPSIS

     use CPAN::Test::Dummy::Perl5::Make::PerlReq::Fail;

=head1 DESCRIPTION

This test dummy lists Perl 6 as a requirement.  It is designed to test how
CPAN and related tools handle failing Perl requirements.

=head1 USAGE

Not intended for any real use.

=head1 SEE ALSO

=over

=item *

L<CPAN>

=back

=head1 AUTHOR

David A. Golden (DAGOLDEN)

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by David A. Golden. All rights reserved.

Licensed under the same terms as Perl itself.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

