package Catmandu::Store::Adlib;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Catmandu::Store::Adlib::Bag;

with 'Catmandu::Store';


#http://pwv.adlibhosting.com/api/wwwopac.ashx?command=
has endpoint => (is => 'ro', required => 1);
has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);
has database => (is => 'ro', required => 1);

1;
__END__

=encoding utf-8

=head1 NAME

Catmandu::Store::Adlib -Retrieve items from a L<Adlib|http://www.adlibsoft.nl/> instance

=head1 SYNOPSIS

    # From the command line
    catmandu export Adlib to YAML --id 1234 --endpoint http://test2.adlibsoft.com --username foo --password bar --database collect.inf

    # From a Catmandu Fix
    lookup_in_store(
      object_priref,
      Adlib,
      endpoint: http://test2.adlibsoft.com,
      username: foo,
      password: bar,
      database: collect.inf
    )

    # From Perl code
    use Catmandu;

    my $store = Catmandu->store('Adlib',
        username => 'foo',
        password => 'bar',
        endpoint => 'http://test2.adlibsoft.com',
        database => 'collect.inf'
    )->bag;

    my $item = $store->get('1234');

=head1 DESCRIPTION

Catmandu::Store::Adlib allows the use of L<Adlib|http://www.adlibsoft.nl/> as a store in Catmandu.

=head1 CONFIGURATION

=head2 endpoint

C<url> of the Adlib API. Do not include the C<api/wwwopac> part; the query builder will append it automatically.

=head2 database

Name of the database (as configured in L<adlibweb.xml|http://api.adlibsoft.com/site/documentation>) you want to query.

=head2 username

Name of a user that can be used to query the API. Only L<Basic Authentication|https://en.wikipedia.org/wiki/Basic_access_authentication> is currently supported.

=head2 password

Password for the user.

=head1 METHODS

=head2 new(%configuration)

Create a new Catmandu::Store::CA

=head2 get($id)

Retrieve a record identified by C<$id>. Note that C<$id> is the I<priref>, not the I<object_number>.

=head2 add($data)

Not supported.

=head2 update($id, $data)

Not supported.

=head2 delete($id)

Not supported.

=head2 each()

List all items in the instance and iterate over them one at the time. Returns a single object.

=head1 AUTHOR

Pieter De Praetere E<lt>pieter@packed.beE<gt>

=head1 COPYRIGHT

Copyright 2017- PACKED vzw, VKC vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
