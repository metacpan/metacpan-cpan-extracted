package Class::ActsLike;

use strict;

use Scalar::Util;
use Class::Roles ();

use vars qw( $VERSION );
$VERSION = '1.00';

BEGIN
{
	*UNIVERSAL::acts_like = \&UNIVERSAL::does;
}

sub import
{
	my ($self, @acts_like) = @_;
	my $caller             = caller();

	for my $role (@acts_like)
	{
		Class::Roles->import( apply => { to => $caller, role => $role } );
	}
}

1;
__END__

=head1 NAME

Class::ActsLike - Perl extension for identifying class behavior similarities

=head1 SYNOPSIS

  package HappyFunBuilding;

  use Class::ActsLike qw( Bakery Arcade );

  ...

  $building->bake( 'cookies' ) if $building->acts_like( 'Bakery' );
  $building->play( 'pinball' ) if $building->acts_like( 'Arcade' );

=head1 DESCRIPTION

B<Note:> This is a deprecated module.  Use L<Class::Roles> for new development.
This module uses C<Class::Roles> internally and exists for the purpose of
backwards compatibility.  The philosophy of the documentation still applies,
though, so enjoy reading it!

Polymorphism is a fundamental building block of object orientation.  Any two
objects that can receive the same messages with identical semantics can
substitute for each other, regardless of their internal implementations.

Much of the introductory literature explains this concept in terms of
inheritance.  While inheritance is one way for two different classes to provide
different behavior for the same methods, it is not the only way.  Perl modules
such as the DBDs or L<Test::MockObject> prove that classes do not have to
inherit from a common ancestor to be polymorphically equivalent.

Class::ActsLike provides an alternative to C<isa()>.

The example class defined above marks C<HappyFunBuilding> as acting like both
the C<Bakery> and C<Arcade> classes.  It is not necessary to create an ancestor
class of C<Building>, or to have C<HappyFunBuilding> inherit from both
C<Bakery> and C<Arcade>.  As well, one could say:

  package FauxArcade;

  use Arcade;
  use Class::ActsLike 'Arcade';

  sub new
  {
	my $class = shift;
	bless { _arcade => Arcade->new() }, $class;
  }

Provided that the FauxArcade now delegates all methods an Arcade object can
receive to the contained Arcade object, this expresses the has-a relationship
more accurately.  Code which requires an Arcade object should, when handed an
object, check to see if the object acts like an Arcade object.  The FauxArcade
is suitable for any sort of Hollywood production where the real Arcade is
unnecessary.  This is why actors always seem so good at pinball.

This technique fulfills two goals:

=over 4

=item *

To allow you to check that the class or object you receive can handle the types
of messages you're going to send it.

=item *

To avoid dictating I<how> the class or object you receive handles the messages:
inheritance, delegation, composition, or re-implementation.

=back

By default, a new class automatically acts like itself, whether you use
C<Class::ActsLike> in its package.  It also automatically acts like all of its
parent classes, again without having had C<Class::ActsLike> used in its
namespace.

=head2 EXPORT

Class::ActsLike installs a new method named C<acts_like()> in the C<UNIVERSAL>
package, so it is available to all classes and objects.  Call it directly on an
object or a class name:

  $class_or_object->acts_like( $potentially_emulated_class );

It returns true or false, depending on whether the class or class of the object
acts like the target class.

=head1 AUTHOR

chromatic C<< chromatic at wgz dot org >>

=head1 THANKS TO

Allison Randal, for debating the theory of this idea.  Dan Sugalski and Dave
Rolsky for understanding the idea.

Larry Wall and the rest of the Perl 6 design team for adding roles to Perl 6.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2003 and 2005, chromatic.

You may use, modify, and distribute this software under the same terms as Perl
5.8.x.  There is no guarantee or warranty.  If something breaks, migrate to
Class::Roles, then file a bug, write a test, and send a patch.

=head1 SEE ALSO

perl(1), L<Class::Roles>, Perl 6 Apocalypse 12 and Synopsis 12.

=cut
