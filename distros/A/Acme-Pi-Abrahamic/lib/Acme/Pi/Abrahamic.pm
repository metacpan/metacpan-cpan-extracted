package Acme::Pi::Abrahamic;
use 5.008003;
our $VERSION = '7.77';

sub import {
    shift;
    my $package = caller();
    no strict "refs";
    *{ $package . "::pi" } = \&pi;
}

sub pi { 3 }

"Take that, subspace.";

__DATA__

=head1 Name 

Acme::Pi::Abrahamic - Pi as related by Abrahamic tradition.

=head1 Synopsis

 use Acme::Pi::Abrahamic;
 my $pi = pi();

 perl -MAcme::Pi::Abrahamic -le 'print pi'

=head1 Bugs

This module is irrefutable.

=head1 Code Repository

L<http://github.com/pangyre/p5-acme-pi-abrahamic>.

=head1 See Also

1 Kings 7:23, 2 Chronicles 4:2.

=head1 Author

Ashley Pond V E<middot> ashley@cpan.org E<middot> L<http://pangyresoft.com>.

=head1 License

You may redistribute and modify this package under the same terms as
Perl itself but only an agent of the Adversary would do so.

=head1 Disclaimer of Warranty

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify or
redistribute the software as permitted by the above license, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut

