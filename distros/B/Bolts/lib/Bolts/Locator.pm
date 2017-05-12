package Bolts::Locator;
$Bolts::Locator::VERSION = '0.143171';
# ABSTRACT: General purpose locator

use Moose;


has root => (
    is          => 'ro',
    isa         => 'HashRef|ArrayRef|Object',
    required    => 1,
);

with 'Bolts::Role::RootLocator';


override BUILDARGS => sub {
    my $class = shift;
    
    if (@_ == 1) {
        return { root => $_[0] };
    }
    else {
        return super();
    }
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Locator - General purpose locator

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    my $some_bag = MyApp::SomeBag->new;
    my $loc = Bolts::Locator->new($some_bag);

    # OR better...
    use Bolts::Util qw( locator_for );
    my $loc = locator_for($some_bag);

=head1 DESCRIPTION

This can be used to wrap any object, array, or hash reference in a L<Bolts::Role::Locator> interface.

=head1 ROLES

=over

=item *

L<Bolts::Role::RootLocator>

=back

=head1 ATTRIBUTES

=head2 root

This implements L<Bolts::Role::Locator/root> allowing the locator to be applied to any object, array or hash reference.

=head1 METHODS

=head2 new

    my $loc = Bolts::Locator->new($bag);
    my $loc = Bolts::Locator->new( root => $bag );

You may call the constructor with only a single argument. In that case, that argument is treated as L</root>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
