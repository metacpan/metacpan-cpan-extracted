package Bolts::Injector::Store::Hash;
$Bolts::Injector::Store::Hash::VERSION = '0.143171';
# ABSTRACT: Inject values into a hash

use Moose;

with 'Bolts::Injector';


has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }


sub post_inject_value {
    my ($self, $loc, $value, $hash) = @_;
    $hash->{ $self->name } = $value;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Injector::Store::Hash - Inject values into a hash

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    my $counter = 0;
    artifact thing => (
        builder => sub { +{} },
        keys => {
            counter => builder { ++$counter },
        },
    );

=head1 DESCRIPTION

This performs injection of a value into a hash.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 ATTRIBUTES

=head2 name

This is the name of the hash key to perform injection upon.

Defaults to the L<Bolts::Injector/key>.

=head1 METHODS

=head2 post_inject_value

Performs the injection into a hash by key.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
