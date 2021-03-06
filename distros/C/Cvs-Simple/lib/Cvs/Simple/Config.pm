#!/usr/bin/perl
# Auto-generated by Makefile.PL
package Cvs::Simple::Config;
use strict;
use warnings;

sub CVS_BIN  () { '/usr/bin/cvs' }
sub EXTERNAL () { '' }

1;

__END__

=pod

=head1 Cvs::Simple::Config

=head1 DESCRIPTION

This module is auto-generated by Makefile.PL during installation of
Cvs::Simple.  Any changes made here will be lost if the module is re-installed
or upgraded.

=head1 FUNCTIONS

=over 4

=item CVS_BIN

Stores location of cvs binary. Defaults to C</usr/bin/cvs>.

=item EXTERNAL

Stores location of external repository, i.e. whatever you would give to C<cvs
-d>.  This function will not appear if the option is not set at install time.

=back

=cut

