# ABSTRACT: Proxyable Object Role for Perl 5
package Data::Object::Role::Proxyable;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Role;
use Data::Object::Library;
use Data::Object::Signatures;

use Carp ();

our $VERSION = '0.59'; # VERSION

method AUTOLOAD {

    my (@namespace) = our $AUTOLOAD =~ /^(.+)::(.+)$/;

    my ($package, $method) = @namespace;

    unshift @_, $self;

    my $build = $package->can('BUILDPROXY');
    my $error = qq(Can't locate object method "$method" via package "$package");

    Carp::confess($error) unless $build && ref($build) eq 'CODE';

    my $proxy = $build->($package, $method, @_);

    Carp::confess($error) unless $proxy && ref($proxy) eq 'CODE';

    goto &$proxy;

}

method DESTROY {

    ; # noop

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Proxyable - Proxyable Object Role for Perl 5

=head1 VERSION

version 0.59

=head1 SYNOPSIS

    use Data::Object::Class;

    with 'Data::Object::Role::Proxyable';

    sub BUILDPROXY {

        my ($class, $method, @args) = @_;

        return sub { ... }; # process method call ...

    }

=head1 DESCRIPTION

Data::Object::Role::Proxyable provides a mechanism for operating on Perl 5
data objects which meet the criteria for being proxyable. This role provides a
wrapper around the AUTOLOAD routine which processes calls to routines which
don't exist.

=head1 SEE ALSO

=over 4

=item *

L<Data::Object::Array>

=item *

L<Data::Object::Class>

=item *

L<Data::Object::Class::Syntax>

=item *

L<Data::Object::Code>

=item *

L<Data::Object::Float>

=item *

L<Data::Object::Hash>

=item *

L<Data::Object::Integer>

=item *

L<Data::Object::Number>

=item *

L<Data::Object::Role>

=item *

L<Data::Object::Role::Syntax>

=item *

L<Data::Object::Regexp>

=item *

L<Data::Object::Scalar>

=item *

L<Data::Object::String>

=item *

L<Data::Object::Undef>

=item *

L<Data::Object::Universal>

=item *

L<Data::Object::Autobox>

=item *

L<Data::Object::Immutable>

=item *

L<Data::Object::Library>

=item *

L<Data::Object::Prototype>

=item *

L<Data::Object::Signatures>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
