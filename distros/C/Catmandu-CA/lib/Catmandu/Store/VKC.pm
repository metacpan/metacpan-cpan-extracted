package Catmandu::Store::VKC;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Catmandu::Store::VKC::Bag;

with 'Catmandu::Store';

extends 'Catmandu::Store::CA';

has username    => (is => 'ro', required => 1);
has password    => (is => 'ro', required => 1);
has model       => (is => 'ro', default => 'ca_objects');
has lang        => (is => 'ro', default => 'nl_NL');
has _field_list => (is => 'rw', default => sub { return []; });


has url         => (is => 'lazy');

sub _build_url {
    my $self = shift;
    return 'http://vkc-ca-prod.inuits.eu';
}

1;
__END__
=encoding utf-8

=head1 NAME

Catmandu::Store::VKC - Retrieve items from the L<CollectiveAccess|http://collectiveaccess.org/> instance of the L<VKC|http://www.vlaamsekunstcollectie.be/>

=head1 SYNOPSIS

    # From the command line
    catmandu export VKC to YAML --id 1234 --username demo --password demo  --model ca_objects --lang nl_NL --field_list 'ca_entities, preferred_labels'

    # From a Catmandu Fix
    lookup_in_store(
      object_id,
      VKC,
      username: demo,
      password: demo,
      lang: nl_NL,
      model: ca_objects,
      field_list: 'ca_entities, preferred_labels'
    )

    # From Perl code
    use Catmandu;

    my $store = Catmandu->store('CA',
        username   => 'demo',
        password   => 'demo',
        lang       => 'nl_NL',
        model      => ca_objects,
        field_list =>'ca_entities, preferred_labels'
    )->bag;

    my $item = $store->get('1234');


=head1 DESCRIPTION

A Catmandu::Store::VKC is Perl package that can query the L<CollectiveAccess|http://collectiveaccess.org> instance of the L<VKC|http://www.vlaamsekunstcollectie.be/>.
It functions identically to L<Catmandu::Store::CA>, but does not require the C<url> parameter to be set.

=head1 CONFIGURATION

=head2 username

Name of a user that can be used to query the API. If you want to store
items in the CA instance, it must have the necessary rights.

=head2 password

Password for the user.

=head2 lang

The language (locale) in which to return the data. Set to C<nl_NL> by default,
will automatically fall back to C<en_US> if the attribute does not exist in the
selected locale. Use the L<IETF language tag|https://en.wikipedia.org/wiki/IETF_language_tag>.

=head2 field_list

A comma-separated, quoted, (C<'foo, bar'>) list of fields that the CollectiveAccess
API should return. Is optional and can be left empty to return the default 'summary'.

=head1 METHODS

=head2 new(%configuration)

Create a new Catmandu::Store::VKC

=head2 get($id)

Retrieve a CA record given an identifier. This returns whatever
the CA administrator designated as the "summary" of the record.

=head2 add($data)

Create a new CA record. See L<here|http://docs.collectiveaccess.org/wiki/Web_Service_API#Creating_new_records> to
see what data you must provide to create a record.

=head2 update($id, $data)

Update a new CA record. See L<here|http://docs.collectiveaccess.org/wiki/Web_Service_API#Creating_new_records> to
see what data you must provide to create a record.

=head2 delete($id)

Delete (I<soft delete>) a record.

=head2 each()

Not supported

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
L<Catmandu::CA::API>

=cut
