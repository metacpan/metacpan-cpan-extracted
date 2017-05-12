package Catmandu::Store::Resolver;

our $VERSION = '0.06';

use Catmandu::Sane;

use Moo;
use Catmandu::Store::Resolver::Bag;
use Catmandu::Store::Resolver::API;

use LWP::UserAgent;

with 'Catmandu::Store';

has url      => (is => 'ro', required => 1);
has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);

has client => (is => 'lazy');

sub _build_client {
    my $self = shift;
    return LWP::UserAgent->new();
}


1;

__END__

=head1 NAME

=for html <a href="https://travis-ci.org/PACKED-vzw/Catmandu-Store-Resolver"><img src="https://travis-ci.org/PACKED-vzw/Catmandu-Store-Resolver.svg?branch=master"></a>

Catmandu::Store::Resolver - Store/retrieve items from the Resolver

=head1 SYNOPSIS

    # From the command line
    $ catmandu export Resolver --id 1234 --url http://www.resolver.be --username demo --password demo to YAML
    ---
    data:
        data_pids:
            - https://resolver.be/collection/work/data/9031
        documents:
            - 88682
            - 88683
        domain: https://resolver.be
        id: '9031'
        persistentURIs:
            - https://resolver.be/collection/9031
            - https://resolver.be/collection/9031/untitled
            - https://resolver.be/collection/work/data/9031/html
            - https://resolver.be/collection/work/data/9031/html/untitled
            - https://resolver.be/collection/work/data/9031
            - https://resolver.be/collection/work/representation/9031/1
            - https://resolver.be/collection/work/representation/9031/1/untitled
            - https://resolver.be/collection/work/representation/9031
        type: work
        work_pid: https://resolver.be/collection/9031
    ...

    # From a Catmandu Fix
    lookup_in_store(
        objectNumber,
        Resolver,
        username: username,
        password: password,
        url: http://www.resolver.be
    )

=head1 DESCRIPTION

    # From a Catmandu Fix
    lookup_in_store(
        objectNumber,
        Resolver,
        username: username,
        password: password,
        url: http://www.resolver.be
    )

Configure the L<Resolver|https://github.com/PACKED-vzw/resolver> as a L<store|http://librecat.org/Catmandu/#stores> for L<Catmandu|http://librecat.org/>.

Museum objects and records require a PID to be uniquely identifiable. The Resolver tool
generates and resolves these PIDs. By using this store, PIDs can be queried (based on
the object number of the record as stored in the resolver), created, updated and deleted
from Catmandu.

The C<_id> attribute of the data after a L<add_to_store|Catmandu::Fix::add_to_store>
is set to the I<workPid>, which is the first item of the I<presistenURIs> array.

The I<Store> returns the following data:

    data:
        data_pids:
            - https://resolver.be/collection/work/data/9031
        documents:
            - 88682
            - 88683
        domain: https://resolver.be
        id: '9031'
        persistentURIs:
            - https://resolver.be/collection/9031
            - https://resolver.be/collection/9031/untitled
            - https://resolver.be/collection/work/data/9031/html
            - https://resolver.be/collection/work/data/9031/html/untitled
            - https://resolver.be/collection/work/data/9031
            - https://resolver.be/collection/work/representation/9031/1
            - https://resolver.be/collection/work/representation/9031/1/untitled
            - https://resolver.be/collection/work/representation/9031
        type: work
        work_pid: https://resolver.be/collection/9031

=head1 PARAMETERS

The Resolver API requires a username and password. These must be provided.

=over

=item C<url>

base url of the Resolver (e.g. I<http://www.resolver.be>).

=item C<username>

username for the Resolver.

=item C<password>

password for the Resolver.

=back

=head1 SEE ALSO

L<Catmandu::Resolver>

=head1 AUTHORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 CONTRIBUTORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 COPYRIGHT AND LICENSE

This package is copyright (c) 2016 by PACKED vzw.
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut