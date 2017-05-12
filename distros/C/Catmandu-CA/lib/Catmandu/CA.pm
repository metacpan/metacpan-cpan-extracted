package Catmandu::CA;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

our $VERSION = '0.06';

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::CA - Catmandu interface to L<CollectiveAccess|http://collectiveaccess.org/>

=head1 SYNOPSIS

    # From the command line
    catmandu export CA to YAML --id 1234 --username demo --password demo --url http://demo.collectiveaccess.org

    # From a Catmandu Fix
    lookup_in_store(
      object_id,
      CA,
      url: http://demo.collectiveaccess.org,
      username: demo,
      password: demo
    )

=head1 MODULES

=over

=item * L<Catmandu::Store::CA>

=item * L<Catmandu::Store::VKC>

=item * L<Catmandu::CA::API>

=back

=head1 AUTHOR

Pieter De Praetere E<lt>pieter at packed.beE<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Catmandu>
L<Catmandu::Store::CA>
L<Catmandu::Store::VKC>
L<Catmandu::CA::API>

=cut
