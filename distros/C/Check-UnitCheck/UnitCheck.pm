package Check::UnitCheck;

use strict;
use warnings;

require DynaLoader;
use AutoLoader;

our @ISA = qw(DynaLoader);
our $VERSION = '0.13';

bootstrap Check::UnitCheck $VERSION;

sub import {
    my $pkg = shift;
    foreach my $sr (@_) {
	_explode("$pkg: need a subref")
	    if ref($sr) ne 'CODE';
    }
    foreach my $sr (@_) {
	unitcheckify($sr);
    }
}

sub _explode {
    require Carp;
    Carp::croak(shift);
}
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Check::UnitCheck - Use best of CHECK or UNITCHECK

=head1 SYNOPSIS

  use Check::UnitCheck sub { ... };
  # runs sub at best of UNITCHECK or global CHECK, depending

=head1 DESCRIPTION

Perl 5.10.0 will include the UNITCHECK block.  This block runs the
moment the compilation unit in which it was defined has finished
compiling.  Perl versions before that had only the CHECK block, which
runs once global compilation has completed, which might or might not
be at the same time that the compilation unit which defines it has
finished.

This module allows you to define a block which will run as a UNITCHECK
block in Perls that allow that, or as a CHECK block in Perls that do
not.  This should allow you to use UNITCHECK semantics in a CPAN
module, while having a moderately graceful fallback for versions of
perl that cannot support that.

Instead of writing:

 CHECK {
   ... code ...
 }

or

 UNITCHECK {
   ... code ...
 }

You instead say:

 use Check::UnitCheck sub {
   ... code ...
 };

At the moment you can only do one sub at once (you can C<use> the
module more than once, though).  In the future extra options might be
provided to allow you to inject these blocks into other modules.

If you want to push a UNITCHECK block into the queue of a compilation
unit that has imported you, then you can do so by calling:

 Check::UnitCheck::unitcheckify(sub {...});

directly.

As code passed into the UNITCHECK or CHECK queue is marked as CvSPECIAL
it is probably unwise to use references to named subroutines.

=head2 EXPORT

None.

=head1 BUGS

perl 5.10 isn't actually available yet, and might not contain
UNITCHECK blocks.  I'll release a version 0.20 of this module once
5.10 exists and this works with it.  Until then, you can use this as a
very complicated way of writing CHECK blocks.

=head1 AUTHOR

Alex Gough (alex@earth.li) http://the.earth.li/~alex/

=head1 COPYRIGHT

This module is (c) Alex Gough, 2006.  You may use and distribute it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.  L<Manip::END>.

=cut
