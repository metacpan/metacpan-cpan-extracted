use 5.008;
use strict;
use warnings;

package Data::Container;
our $VERSION = '1.100840';
# ABSTRACT: Base class for objects containing a list of items

# Implements a container object.
use Carp;
use Data::Miscellany 'set_push';
use parent 'Class::Accessor::Complex';
use overload
  '""' => 'stringify',
  cmp  => sub { "$_[0]" cmp "$_[1]" };
__PACKAGE__
    ->mk_new
    ->mk_array_accessors('items');

sub stringify {
    join "\n\n" => map { "$_" } $_[0]->items;
}

sub items_set_push {
    my ($self, @values) = @_;
    set_push @{ $self->{items} },
      map { ref($_) && UNIVERSAL::isa($self, ref $_) ? $_->items : $_ } @values;
}

sub prepare_comparable {
    my $self = shift;
    $self->items;    # autovivify
}

sub item_grep {
    my ($self, $spec) = @_;
    grep { ref($_) eq $spec } $self->items;
}
1;


__END__
=pod

=head1 NAME

Data::Container - Base class for objects containing a list of items

=head1 VERSION

version 1.100840

=head1 SYNOPSIS

    package My::Container;
    use parent 'Data::Container';
    # ...

    package main;
    my $container = My::Container->new;
    $container->items_push('some_item');

=head1 DESCRIPTION

This class implements a container object. The container can contain any
object, scalar or reference you like. Typically you would subclass
Data::Container and implement custom methods for your specific container.

When the container is stringified, it returns the concatenated
stringifications of its items, each two items joined by two newlines.

=head1 METHODS

=head2 items_set_push

Like C<items_push()>, and it also takes a list of items to push into the
container, but it doesn't push any items that are already in the container
(items are compared deeply to determine equality).

=head2 item_grep

Given a package name, it returns those items from the container whose C<ref()>
is equal to that package name.

For example, your container could contain some items of type C<My::Item::Foo>
and some of type C<My::Item::Bar>. If you only want a list of the items of
type C<My::Item::Foo>, you could use:

    my @foo_items = $container->item_grep('My::Item::Foo');

=head2 stringify

Stringifies the data container by concatenating the items together, separated
by an empty line.

=head2 prepare_comparable

Adds support for L<Data::Comparable> by autovivifying the container items
array.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Container>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Container/>.

The development version lives at
L<http://github.com/hanekomu/Data-Container/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

