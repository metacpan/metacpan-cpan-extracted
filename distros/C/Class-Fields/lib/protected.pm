package protected;

use strict;

use vars qw($VERSION);

$VERSION = 0.04;

use Class::Fields::Fuxor;
use Class::Fields::Attribs;

sub import {
    #Dump the class.
    shift;
    
    my $package = caller;
    add_fields($package, PROTECTED, @_);
}

return <<TIP;
Protect your member!  Wear a cup!
TIP

__END__
=pod

=head1 NAME

protected - "private" data fields which are inherited by child classes


=head1 SYNOPSIS

    package Foo;
    use public      qw(foo bar );
    use private     qw(_private);
    use protected   qw(_pants spoon);
    
    sub squonk {
        my($self) = shift;
        $self->{_pants} = 'Infinite Trousers';
        $self->{spoon}  = 'What stirs me, stirs everything';
        ...
    }
    
    package Bar;
    # Inherits foo, bar, _pants and spoon
    use base qw(Foo);
    ...
    

=head1 DESCRIPTION

=over 4

=item I<Protected member.>

Restricted data or functionality.  An attribute or method only
directly accessible to methods of the same class or of a subclass, but
inaccessible from any other scope.

From B<"Object Oriented Perl"> by Damian Conway

=back

The C<protected> module implements something like Protected data
members you might find in a language with a more traditional OO
implementation such as C++.

Protected data members are similar to private ones with the notable
exception in that they are inherited by subclasses.  This is useful
where you have private information which would be useful for
subclasses to know as well.

For example: A class which stores an object in a database might have a
protected member "_Changed" to keep track of changes to the object so
it does not have to waste time re-writing the entire thing to disk.
Subclasses of this obviously need a _Changed field as well, but it
would be breaking encapsilation if the author had to remember to "use
fields qw(_Changed)" (Assuming, of course, they're using fields and
not just a plain hash.  In which case forget this whole module.)


=head2 The Camel Behind The Curtain

In reality, there is little difference between a "protected" variable
and a "public" on in Perl.  The only real difference is that the
protected module doesn't care what the field is called (ie. if it
starts with an underscore or not) whereas fields uses the name to
determine if the variable is public or private (ie. inherited or not).


=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 SEE ALSO

L<public>, L<private>, L<fields>, L<Class::Fields>, L<base>

=cut
