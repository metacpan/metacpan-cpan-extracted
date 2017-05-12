
=head1 NAME

Class::Accessor::Fast::XS - XS replacement for Class::Accessor::Fast

=head1 OBSOLETE NOTE

This module has been stated rudimentary in favor of
L<Class::XSAccesor::Compat>, that implements the same API.
Steffen Mueller did a great job improving concept of XS
accessors in L<Class::XSAccesor> framework and keep improving it
further.

At this moment (Dec 2010) Class::XSAccesor::Compat generates 25%
faster accessors than this module and has some thread safety fixes.
There is no point in porting fixes or improvements from Steffen's
code as you can just change the name and switch over.

=head1 DESCRIPTION

This module is a XS based replacement for L<Class::Accessor::Fast>.
Just replace Class::Accessor::Fast with Class::Accessor::Fast::XS and
it should just work.

Read L<Class::Accessor::Fast> and L<Class::Accessor> for API docs and
usage.

XS is about performance, but usually optimized accessors like
L<Class::Accessor::Fast> and many other with similar optimizations
give you enough performance to make accessors NOT a bottleneck.
In a real applications switch from Class::Accessor::Fast to this
module can give you 1-5% boost.

Want to compare performance of different solutions?
Use L<App::Benchmark::Accessors>, but do remember that these benchmarks
don't take into account various properties and advances of different
implementations.

=cut

package Class::Accessor::Fast::XS;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.04';

use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

sub new {
    return bless
        defined $_[1]
            ? {%{$_[1]}} # make a copy of $fields.
            : {},
        ref $_[0] || $_[0];
}

sub make_ro_accessor {
    my($class, $field) = @_;

    my $sub = $class ."::__xs_ro_". $field;
    xs_make_ro_accessor($sub, $field);

    no strict 'refs';
    return \&{$sub};
}

sub make_wo_accessor {
    my($class, $field) = @_;

    my $sub = $class ."::__xs_wo_". $field;
    xs_make_wo_accessor($sub, $field);

    no strict 'refs';
    return \&{$sub};
}

sub make_accessor {
    my($class, $field) = @_;

    my $sub = $class ."::__xs_". $field;
    xs_make_accessor($sub, $field);

    no strict 'refs';
    return \&{$sub};
}

=head1 CREDITS

This code is heavily based on Steffen Mueller's L<Class::XSAccessor>.

=head1 SEE ALSO

There are enormous amount of different accessors generators with different
properties, behavior and performance, here is list of some:

L<accessors>, L<Class::Accessor>, L<Class::MethodMaker>, L<Class::XSAccessor>,
L<Object::Accessor>...

=head1 AUTHOR

Ruslan Zakirov E<lt>Ruslan.Zakirov@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
