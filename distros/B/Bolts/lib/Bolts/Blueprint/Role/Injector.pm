package Bolts::Blueprint::Role::Injector;
$Bolts::Blueprint::Role::Injector::VERSION = '0.143171';
# ABSTRACT: Tags a blueprint as being usable during injection

use Moose::Role;

with 'Bolts::Blueprint';


requires 'exists'; 
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Blueprint::Role::Injector - Tags a blueprint as being usable during injection

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

This role tags a class as a blueprint that may be used for injection. The difference between a common blueprint and an injector blueprint is that the parameters passed for an injector will always be passed as a hash in list form. Whereas a regular blueprint may receive any kind of argument list. Also, the injection parameters are not as well targeted or filtered as they are during regular blueprint resolution.

A blueprint may implement this instead of L<Bolts::Blueprint> if it could be useful to during injection and ignores or is able to process parameters as a hash.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint>

=back

=head1 REQUIRED METHODS

=head2 exists

    my $exists = $blueprint->exists($bag, $name, %params);

Given a set of parameters, this returns whether or not the value provided by the blueprint exists or not. This is used to determine whether or not the injector should even be run.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
