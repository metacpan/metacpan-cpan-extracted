package Bolts::Artifact::Thunk;
$Bolts::Artifact::Thunk::VERSION = '0.143171';
# ABSTRACT: Simplified artifact implementation

use Moose;


has thunk => (
    is          => 'ro',
    isa         => 'CodeRef',
    traits      => [ 'Code' ],
    handles     => {
        'get' => 'execute_method',
    },
);


# TODO Fix this. Make it do something rather than ignore the check.
sub such_that { }

with 'Bolts::Role::Artifact';

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Artifact::Thunk - Simplified artifact implementation

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    my $artifact = Bolts::Artifact::Thunk->new(
        thunk => sub {
            my ($artifact, $bag, %parameters) = @_;
            return MyApp::Thing->new(%parameters);
        },
    );

=head1 DESCRIPTION

This provides a greatly simplified implementation of L<Bolts::Role::Artifact>. This skips out on all of the main features of Bolts by just boiling the artifact definition down to the simplest possible form. There are no blueprints, no scope, no injection, just a thunk that does the work.

This is handy for cases where a full-blown artifact implementation is tedious or impossible, particularly when bootstrapping L<Bolts::Meta::Locator>. 

It may also be used when you just need a shortcut or optimization. That said, you will probably regret any extensive use of this. (I mean, really, why bother with the Bolt framework if you just short-circuit major bits down to this? You could just implement something simpler and probably faster.)

=head1 ROLES

=over

=item *

L<Bolts::Role::Artifact>

=back

=head1 ATTRIBUTES

=head2 thunk

This is the code reference used to construct the artifact. It will be called every time the artifact is resolved.

=head1 METHODS

=head2 get

This is implemented using the C<execute_method> of L<Moose::Meta::Attribute::Trait::Native::Code> on L</thunk>.

=head2 such_that

Not implemented.

B<Caution:> In the future, this will probably be implemented. 

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
