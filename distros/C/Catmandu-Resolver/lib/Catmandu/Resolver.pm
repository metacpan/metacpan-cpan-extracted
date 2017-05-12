package Catmandu::Resolver;

our $VERSION = '0.06';

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

1;
__END__

=head1 NAME

=for html <a href="https://travis-ci.org/PACKED-vzw/Catmandu-Store-Resolver"><img src="https://travis-ci.org/PACKED-vzw/Catmandu-Store-Resolver.svg?branch=master"></a>

Catmandu::Resolver - Store/retrieve items from the Resolver

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

    # Create or retrieve a PID from a fix
    make_pid(
        path,
        'http://www.resolver.be',
        username,
        password,
        -type: work
    )

=head1 DESCRIPTION

Configure the L<Resolver|https://github.com/PACKED-vzw/resolver> as a L<store|http://librecat.org/Catmandu/#stores> for L<Catmandu|http://librecat.org/>.

Museum objects and records require a PID to be uniquely identifiable. The Resolver tool
generates and resolves these PIDs. By using this store, PIDs can be queried (based on
the object number of the record as stored in the resolver), created, updated and deleted
from Catmandu.

=head1 MODULES

=over

=item L<Catmandu::Store::Resolver>

=item L<Catmandu::Fix::make_pid>

=back

=head1 SEE ALSO

L<Catmandu>

=head1 AUTHORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 CONTRIBUTORS

Pieter De Praetere, C<< pieter at packed.be >>

=head1 COPYRIGHT AND LICENSE

This package is copyright (c) 2016 by PACKED vzw.
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut