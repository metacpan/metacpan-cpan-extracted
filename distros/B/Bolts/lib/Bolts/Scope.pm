package Bolts::Scope;
$Bolts::Scope::VERSION = '0.143171';
# ABSTRACT: The interface for lifecycle managers

use Moose::Role;


requires 'get';
requires 'put';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Scope - The interface for lifecycle managers

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

This describes the interface to be implemented by all artifact scopes, which are used to manage the lifecycles of artifacts in the Bolts system.

=head1 REQUIRED METHODS

=head2 get

    my $artifact = $scope->get($bag, $name);

Fetches the named value out of the scope cache for the given bag.

=head2 put

    $scope->put($bag, $name, $artifact);

Stores the named value into the scope cache for the given bag.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
