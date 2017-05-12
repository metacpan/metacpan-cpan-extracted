package Bolts::Injector::Store::Array;
$Bolts::Injector::Store::Array::VERSION = '0.143171';
# ABSTRACT: Inject dependencies into array artifacts

use Moose;

with 'Bolts::Injector';


has position => (
    is          => 'ro',
    isa         => 'Int',
    predicate   => 'has_position',
);


sub post_inject_value {
    my ($self, $loc, $value, $array) = @_;
    if ($self->has_position) {
        $array->[ $self->position ] = $value;
    }
    else {
        push @{ $array }, $value;
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Injector::Store::Array - Inject dependencies into array artifacts

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    artifact thing1 => (
        builder => sub { [] },
        indexes => [
            0 => value 'first',
            2 => value 'third',
            9 => value 'tenth',
        ],
    );

    my $counter = 0;
    artifact thing2 => (
        builder => sub { [ 'foo', 'bar' ] },
        push => [ value 'baz', builder { ++$counter } ],
    );

=head1 DESCRIPTION

Inject values into an array during resolution by index or just push.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 ATTRIBUTES

=head2 position

If this attribute is set to a number, then the injection will happen at that index. If it is not set, this injector performs a push instead.

=head1 METHODS

=head2 post_inject_value

Performs the injection of values into an array by index or push.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
