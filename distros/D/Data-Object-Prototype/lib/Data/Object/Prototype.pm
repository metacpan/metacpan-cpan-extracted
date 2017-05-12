# ABSTRACT: Data::Object Prototype-based Programming
package Data::Object::Prototype;

use 5.10.0;

use strict;
use warnings;

use Carp ();

use Data::Object::Class;
use Data::Object::Signatures;

use Data::Object::Prototype::Attribute;
use Data::Object::Prototype::Method;

use Data::Object::Library -types;

our $VERSION = '0.06'; # VERSION

has 'package' => (
    is      => 'ro',
    isa     => Str,
    default => fun { join '::', ref shift, '__ANON__' },
    lazy    => 1,
);

has 'series' => (
    is      => 'ro',
    isa     => Str,
    default => fun { join '::', shift->package, 'Instance' },
    lazy    => 1,
);

has 'inherits' => (
    is      => 'ro',
    isa     => ArrayObj[Str],
    default => fun { [] },
    coerce  => 1,
    lazy    => 1,
);

has 'includes' => (
    is      => 'ro',
    isa     => ArrayObj[Str],
    default => fun { [] },
    coerce  => 1,
    lazy    => 1,
);

has 'attributes' => (
    is      => 'ro',
    isa     => ArrayObj[InstanceOf['Data::Object::Prototype::Attribute']],
    default => fun { [] },
    coerce  => 1,
    lazy    => 1,
);

has 'methods' => (
    is      => 'ro',
    isa     => ArrayObj[InstanceOf['Data::Object::Prototype::Method']],
    default => fun { [] },
    coerce  => 1,
    lazy    => 1,
);

fun BUILDARGS ($class, %args) {
    my @properties = grep qr/^[\&\$]/, sort keys %args;

    for my $key (@properties) {
        if (my ($name) = $key =~ /\$(\w+)/) {
            push @{$args{attributes}} =>
                Data::Object::Prototype::Attribute->new(
                    name    => $name,
                    options => $args{$key},

                );
        }
        if (my ($name) = $key =~ /\&(\w+)/) {
            push @{$args{methods}} =>
                Data::Object::Prototype::Method->new(
                    name    => $name,
                    routine => $args{$key},
                );

        }
    }

    return \%args;
}

my %counter;
method class () {
    my $series    = $self->series;
    my $format    = join '::', $series, '%04d';
    my $instance  = sprintf $format, ++$counter{$series};
    my @statement = "package $instance";
    my @supers    = 'Data::Object::Prototype::Instance';
    my $default   = 'Data::Object::Class';

    if (my $inherits = $self->inherits) {
        push @supers, $inherits->list;
    }

    push @statement, "use $default",
        map "extends '$_'", @supers, ();

    unless ($counter{$instance}++) {
        local $@; eval join '; ', @statement; Carp::croak $@ if $@;
    }

    my $package = $instance->package;

    $package->method(prototype => sub { $self });

    my $methods = $self->methods;
    for my $method ($methods->list) {
        my $name = $method->name;
        my $data = $method->routine->data;
        $package->method($name, $data);
    }

    my $includes = $self->includes;
    for my $include ($includes->list) {
        $package->mixin_role($include);
    }

    my $attributes = $self->attributes;
    for my $attribute ($attributes->list) {
        my $name = $attribute->name;
        my $data = $attribute->options;
        $package->attribute($name, @$data);
    }

    return $instance;
}

method create ($class: %args) {
    return $class->new(%args)->class;
}

method extend (%args) {
    $args{package}    //= $self->package,
    $args{series}     //= $self->series,
    $args{inherits}   //= $self->inherits,
    $args{includes}   //= $self->includes,
    $args{attributes} //= $self->attributes,
    $args{methods}    //= $self->methods,

    return ref($self)->new(%args)->class;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Prototype - Data::Object Prototype-based Programming

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Data::Object::Prototype;

=head1 DESCRIPTION

Data::Object::Prototype implements a thin prototype-like layer on top of the
L<Data::Object> data-type object framework. This module allows you to develop
using a prototype-based style in Perl, giving you the ability to create,
mutate, extend, mixin, and destroy anonymous classes, ad hoc and with very
little code.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
