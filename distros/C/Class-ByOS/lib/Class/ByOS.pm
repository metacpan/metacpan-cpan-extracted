#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package Class::ByOS;

use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.02';

our @EXPORT = qw( new );

=head1 NAME

C<Class::ByOS> - write object classes that load OS-specific subclasses at runtime

=head1 SYNOPSIS

This module is for authors of object classes. A class might be written as

 package System::Wobble;

 use Class::ByOS;

 # NOT new()
 sub __new
 {
    my $class = shift;
    my @args = @_;
    ...

    return bless { internals => here }, $class;
 }

 sub wobble
 {
    # we'll just shell out to the 'wobble' binary
    system( "wobble" );
 }

 1;

The user of this class doesn't need to know the details; it can be used like

 use System::Wobble;

 my $wobbler = System::Wobble->new();
 $wobbler->wobble;

An OS-specific implementation can be provided in a subclass

 package System::Wobble::wobblyos;

 use base qw( System::Wobble );

 use WobblyOS::Wobble qw( sys_wobble );

 sub wobble { sys_wobble() }

 1;

=head1 DESCRIPTION

Often a module will provide a general functionallity that in some way uses the
host system's facilities, but in a way that can either benefit from, or
requires an implementation specific to that host OS. Examples might be IO
system calls, access to networking or hardware devices, kernel state, or other
specific system internals.

By implementing a base class using this module, a special constructor is
formed that, at runtime, probes the available modules, constructing an
instance of the most specific subclass that is appropriate. This allows the
object's methods, including its actual constructor, to be overridden for
particular OSes, in order to provide functionallity specifically to that OS,
without sacrificing the general nature of the base class.

The end-user program that uses such a module does not need to be aware of this
magic. It simply constructs an object in the usual way by calling the class's
C<new()> method and use the object reference returned.

=cut

=head1 EXPORTED CONSTRUCTOR

=cut

=head2 $obj = $class->new( @args )

By default, this module exports a C<new()> function into its importer, which
is the constructor actually called by the end-user code. This constructor will
determine the best subclass to use (see C<find_best_subclass()>), then invoke
the C<__new()> method on that class, passing in all its arguments.

=cut

# This is the EXPORTED new()
sub new
{
   find_best_subclass( shift )->__new( @_ );
}

=head1 FUNCTIONS

=cut

=head2 $class = find_best_subclass( $baseclass )

This function attempts to find suitable subclasses for the base class name
given. Candidates for being chosen will be

=over 4

=item C<$class::$^O>

=item C<$class>

For each candidate, it will be picked if that package provides a method called
C<__new>. If it does not exist yet, then an attempt will be made to load the
package using C<require>. If this attempt succeeds and the C<__new> method now
exists, then the candidate will be picked.

=back

=cut

sub find_best_subclass
{
   my $class = shift;

   eval { try_class( "${class}::$^O" ) } or
   # TODO: try OS families here; e.g. linux -> POSIX
   $class;
}

sub try_class
{
   my $class = shift;

   $class->can( "__new" ) and return $class;

   ( my $path = "$class.pm" ) =~ s{::}{/}g;
   eval { require $path } and $class->can( "__new" ) and return $class;

   return undef;
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 TODO

=over 4

=item *

Get C<find_best_subclass()> to check OS family names too. E.g. "linux" would
also try Unix, or POSIX, or something of that nature. Need a source of these
names from somewhere. Tempted to try C<Devel::CheckOS> but that can't
distinguish OS names from families, nor can it provide taxonomy ordering.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
