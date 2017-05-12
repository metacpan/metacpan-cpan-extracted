package Bolts::Inference;
$Bolts::Inference::VERSION = '0.143171';
# ABSTRACT: This is the interface for inferring injectors from a blueprint

use Moose::Role;


requires 'infer';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Inference - This is the interface for inferring injectors from a blueprint

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    package MyApp::Inference::Frobnicator;
    use Moose;

    with 'Bolts::Inference';

    sub infer {
        my ($self, $blueprint) = @_;

        return unless $blueprint->ia('MyApp::Blueprint::Frobnicator');

        my $type = $blueprint->type_of_thingamajig;

        my @parameters;
        if ($type eq 'foo') {
            push @parameters, {
                key        => 'foo',
                inject_via => [ 'injector, 'setter' ],
            };
            push @parameters, {
                key        => 'bar',
                inject_via => [ 'injector', 'parameter_name' ],
            };
        }
        elsif ($type eq 'bar') {
            push @parameters, {
                key        => 'bar',
                inject_via => [ 'injector', 'setter' ],
            };
            push @parameters, {
                key        => 'foo',
                inject_via => [ 'injector', 'parameter_name' ],
            };
        }
        else {
            die "cannot infer from type [$type]";
        }
    }

=head1 DESCRIPTION

Defines the interface for Bolts inferrers. An inferrer is an object that is able
to examine a blueprint and from that blueprint determine what parameters,
settings, etc. the artifact constructed by the blueprint needs or may accept.

=head1 REQUIRED METHODS

=head2 infer

    my @parameters = $inferrer->infer($blueprint);

Given a blueprint, this must return a list of parameter descriptions, which are returned as a hash. Each element may contain the following keys:

=over

=item key

This is the name to give the parameter for injection.

=item inject_via

This is the full path to the injector to qcquire, found within the meta locator, usually L<Bolts::Meta::Locator>, usually under the "injector" key.

=item isa

This is the type constraint the injected value must adhere to.

=item does

This is the role type the injected value must adhere to.

=item required

This stats whether or not the parameter is required to complete the blueprint or not.

=back

Notice that the blueprint is not determined by the inferer. This is handled by L<Bolts::Artifact> instead, via the L<Bolts::Artifact/infer> setting on the artifact in question.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
