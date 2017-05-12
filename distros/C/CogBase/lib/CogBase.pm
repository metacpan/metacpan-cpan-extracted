package CogBase;

use 5.006001;
use strict;
use warnings;
our $VERSION = '0.10';

use CogBase::Base -base;

const connection_class => 'CogBase::Connection';

sub connect {
    my ($class, $path) = @_;
    my $connection_class = $class->connection_class;
    eval "require $connection_class; 1"
        or die $@;
    $connection_class->connection($path);
}

__END__

=head1 NAME

CogBase - A CogBase Implementation in Perl

=head1 WARNING

This Database implementation is in its infancy. Just barely a proof of
concept so far. It would be ridiculous of you to use it for anything
serious, yet.

=head1 SYNOPSIS

    use CogBase;

    my $conn = CogBase->connect('http://cog.example.com');

    my $schema = $conn->node('Schema');
    $schema->value(<<'...');
    +: person
    <: Node
    age: Number
    given_name: String
    family_name: String
    ...
    $conn->store($schema);

    my $person = $conn->node('person');

    $person->given_name('Ingy');
    $person->family_name('dot Net');
    $person->age(42);

    $conn->store($person);

    my @results = $conn->query('!person');
    my @nodes = $conn->fetch(@results);

    for my $node (@nodes) {
        print "%s %s is %d years old\n",
            $node->given_name,
            $node->family_name,
            $node->age;
    }

    $conn->disconnect;

=head1 DESCRIPTION

CogBase is a Object Database Management System.

Some interesting characteristics of its design are:

=over

=item * All objects are stored as nodes.

=item * Every node has a universally unique id.

=item * Every node has a type.

=item * Every type has a schema.

=item * Every schema, is itself, a node in the db.

=item * Every schema has a base/super schema that it inherits from.

=item * Schemas can be used to generate programming language (Perl) classes
for every type (schema) of node.

=item * CogBase defines several core scalar types.

=item * CogBase defines one core schema (that every schema inherits from).

=item * Every node has one or more revisions.

=item * Every revision is immutable.

=item * Database access methods are connect, create, store, fetch, query
and disconnect.

=item * All nodes have access control based on the Unix File System.

=item * HTTP is used for the network layer. GET and POST are used for all
operations.

=item * Database can be used over network or embedded.

=item * Access control is based on Unix File System

=back

=head1 AUTHOR

Ingy döt Net, C<< <ingy at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cogbase at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CogBase>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CogBase

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CogBase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CogBase>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CogBase>

=item * Search CPAN

L<http://search.cpan.org/dist/CogBase>

=back

=head1 ACKNOWLEDGEMENTS

Unix, HTTP

=head1 COPYRIGHT & LICENSE

Copyright 2006 Ingy döt Net, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of CogBase
