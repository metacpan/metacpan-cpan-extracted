package Bolts::Injector::Parameter::ByName;
$Bolts::Injector::Parameter::ByName::VERSION = '0.143171';
# ABSTRACT: Inject parameters by name during construction

use Moose;

with 'Bolts::Injector';


has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }


sub pre_inject_value {
    my ($self, $loc, $value, $params) = @_;
    push @{ $params }, $self->name, $value;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Injector::Parameter::ByName - Inject parameters by name during construction

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    artifact thing => (
        class => 'MyApp::Thing',
        parameters => {
            foo => dep('other_thing'),
        },
    );

=head1 DESCRIPTION

Inject parameters by name during construction.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 ATTRIBUTES

=head2 name

This is the name of the parameter to set in the call to the constructor.

=head1 METHODS

=head2 pre_inject_value

Performs the pre-injection by named parameter.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
