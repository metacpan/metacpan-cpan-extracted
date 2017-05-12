package Data::Clone;

use 5.008_001;
use strict;

our $VERSION = '0.004';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use parent qw(Exporter);
our @EXPORT    = qw(clone);
our @EXPORT_OK = qw(data_clone TIECLONE);

sub data_clone;
*data_clone = \&clone; # alias

sub TIECLONE;
*TIECLONE = \&clone; # alias

1;
__END__

=head1 NAME

Data::Clone - Polymorphic data cloning

=head1 VERSION

This document describes Data::Clone version 0.004.

=head1 SYNOPSIS

    # as a function
    use Data::Clone;

    my $data   = YAML::Load("foo.yml"); # complex data structure
    my $cloned = clone($data);

    # makes Foo clonable
    package Foo;
    use Data::Clone;
    # ...

    # Foo is clonable
    my $o = Foo->new();
    my $c = clone($o); # $o is deeply copied

    # used for custom clone methods
    package Bar;
    use Data::Clone qw(data_clone);
    sub clone {
        my($proto) = @_;
        my $object = data_clone($proto);
        $object->do_something();
        return $object;
    }
    # ...

    # Bar is also clonable
    $o = Bar->new();
    $c = clone($o); # Bar::clone() is called

=head1 DESCRIPTION

C<Data::Clone> does data cloning, i.e. copies things recursively. This is
smart so that it works with not only non-blessed references, but also with
blessed references (i.e. objects). When C<clone()> finds an object, it
calls a C<clone> method of the object if the object has a C<clone>, otherwise
it makes a surface copy of the object. That is, this module does polymorphic
data cloning.

Although there are several modules on CPAN which can clone data,
this module has a different cloning policy from almost all of them.
See L</Cloning policy> and L</Comparison to other cloning modules> for
details.

=head2 Cloning policy

A cloning policy is a rule that how a cloning routine copies data. Here is
the cloning policy of C<Data::Clone>.

=head3 Non-reference values

Non-reference values are copied normally, which will drop their magics.

=head3 Scalar references

Scalar references including references to other types of references
are B<not> copied deeply. They are copied on surface
because it is typically used to refer to something unique, namely
global variables or magical variables.

=head3 Array references

Array references are copied deeply. The cloning policy is applied to each
value recursively.

=head3 Hash references

Hash references are copied deeply. The cloning policy is applied to each
value recursively.

=head3 Glob, IO and Code references

These references are B<not> copied deeply. They are copied on surface.

=head3 Blessed references (objects)

Blessed references are B<not> copied deeply by default, because objects might
have external resources which C<Data::Clone> could not deal with.
They will be copied deeply only if C<Data::Clone> knows they are clonable,
i.e. they have a C<clone> method.

If you want to make an object clonable, you can use the C<clone()> function
as a method:

    package Your::Class;
    use Data::Clone;

    # ...
    my $your_class = Your::Class->new();

    my $c = clone($your_object); # $your_object->clone() will be called

Or you can import C<data_clone()> function to define your custom clone method:

    package Your::Class;
    use Data::Clone qw(data_clone);

    sub clone {
        my($proto) = @_;
        my $object = data_clone($proto);
        # anything what you want
        return $object;
    }

Of course, you can use C<Clone::clone()>, C<Storable::dclone()>, and/or
anything you want as an implementation of C<clone> methods.

=head2 Comparison to other cloning modules

There are modules which does data cloning.

C<Storable> is a standard module which can clone data with C<dclone()>.
It has a different cloning policy from C<Data::Clone>. By default it tries
to make a deep copy of all the data including blessed references, but you
can change its behaviour with specific hook methods.

C<Clone> is a well-known cloning module, but it does not polymorphic
cloning. This makes a deep copy of data regardless of its types. Moreover, there
is no way to change its behaviour, so this is useful only for data which
link to no external resources.

C<Data::Clone> makes a deep copy of data only if it knows that the data are
clonable. You can change its behaviour simply by defining C<clone> methods.
It also exceeds C<Storable> and C<Clone> in performance.

=head1 INTERFACE

=head2 Exported functions

=head3 B<< clone(Scalar) >>

Returns a copy of I<Scalar>.

=head2 Exportable functions

=head3 B<< data_clone(Scalar) >>

Returns a copy of I<Scalar>.

The same as C<clone()>. Provided for custom clone methods.

=head3 B<< is_cloning() >>

Returns true inside the C<clone()> function, false otherwise.

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to the author.

=head1 SEE ALSO

L<Storable>

L<Clone>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
