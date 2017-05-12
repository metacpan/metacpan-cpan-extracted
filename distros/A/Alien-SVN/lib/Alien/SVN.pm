package Alien::SVN;

use version;  our $VERSION = qw(1.8.11.0);

=head1 NAME

Alien::SVN - A wrapper for installing the SVN Perl bindings

=head1 DESCRIPTION

Alien::SVN is a wrapper to install the Perl bindings for subversion,
also known as L<SVN::Core>.  If your module needs L<SVN::Core> it can
depend on SVN::Core normally, then CPAN clients can resolve the
dependency normally via Alien::SVN.  This is particularly useful for
programs like SVK.

It comes with a copy of Subversion 1.8.11 which it will compile but
only installs the Perl and Subversion libraries.  They will be
installed to your Perl library, not your system library.  B<The
subversion binaries will not be installed>.


=head1 BUGS and FEEDBACK

Alien::SVN only wraps SVN::Core.  We don't work on it.

Bug reports, problems and feedback about the Alien::SVN distribution
and building SVN::Core should come to us at
L<https://github.com/evalEmpire/Alien-SVN/issues>.

Issues and improvements to SVN::Core should go to the Apache Subversion
project directly.  L<https://subversion.apache.org/reporting-issues.html>

If you're not sure who to report to, you can always report to us and
we'll point you in the right direction.

Report early, report often.

The repository can be found at F<https://github.com/evalEmpire/Alien-SVN>.

=head1 LICENSE

Alien::SVN is copyright 2007-2015 Michael G Schwern E<lt>schwern@pobox.comE<gt>
It is licensed under the same terms as Perl itself.
See L<http://www.perl.com/perl/misc/Artistic.html> for licensing.

This product includes Apache Subversion licensed under the Apache
License 2.0 or similar terms.  See F<src/subversion/LICENSE> for full
licensing information.

=cut

1;
