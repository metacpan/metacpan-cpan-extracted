package Bolts::Injector::Parameter::ByPosition;
$Bolts::Injector::Parameter::ByPosition::VERSION = '0.143171';
# ABSTRACT: Inject parameters by position during construction

use Moose;

with 'Bolts::Injector';


sub pre_inject_value {
    my ($self, $loc, $value, $params) = @_;
    push @{ $params }, $value;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Injector::Parameter::ByPosition - Inject parameters by position during construction

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    artifact thing => (
        class => 'MyApp::Thing',
        parameters => [
            dep('other_thing'),
        ],
    );

=head1 DESCRIPTION

Inject parameters by position during construction.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 METHODS

=head2 pre_inject_value

Perform the pre-injection of the parameter by position.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
