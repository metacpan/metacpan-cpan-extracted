package Class::CanBeA;

use strict;
use warnings;

our $VERSION = '1.4';

sub subclasses {
    no strict 'refs';
    my($superclass, $namespace) = @_;
    die("Need to specify superclass when looking for subclasses\n")
        unless($superclass);
    $namespace = (($namespace) ? $namespace : 'main').'::';
    (my $parent = $namespace)=~ s/^main::$//;
    my @children = ();
    foreach my $child (
        map { s/::$//; $_ }
        grep { $_ ne 'SUPER::' && $_ ne '<none>::' && $_ ne 'main::' && $_ ne '0::' && !/^::/ && /::$/ } 
        keys %{$namespace}
    ) {
        push @children, $parent.$child if("$parent$child"->isa($superclass));
        push @children, @{subclasses($superclass, $parent.$child)};
    }
    return [grep { $_ ne $superclass } @children];
}

=head1 NAME

Class::CanBeA - figure out what your class can be.

=head1 SYNOPSIS

    use Class::CanBeA;

    my @subclasses = @{Class::CanBeA::subclasses('My::Class')};

=head1 DETAILS

This package provides just one function, which it does *not* export, so you
need to call it by its fully qualified name.

=head1 FUNCTIONS

=head2 subclasses

Takes a single argument, which should be a class name.  It returns a
reference to an array of all the classes which are loaded and which are
subclasses of the specified superclass.

Internally it recurses and passes other parameters to that function, but you
don't need to know that, so I haven't mentioned it.  Right?

=head1 BUGS/LIMITATIONS

No attempt is made to deal with circular inheritance.

Will only tell you about loaded and defined classes, obviously.

=head1 AUTHOR

David Cantrell E<lt>david@cantrell.org.ukE<gt>

=head1 FEEDBACK

Please let me know if you find this module useful.  If reporting a bug,
it's helpful to include a minimal code snippet which I can use in the
test suite.

=head1 SEE ALSO

  Class::ISA

=head1 LICENCE

You may use, modify, distribute and have fun with this software under the
same terms as you can with perl itself.  You may even use it as a device
for distracting leopards.

=cut

'false';
