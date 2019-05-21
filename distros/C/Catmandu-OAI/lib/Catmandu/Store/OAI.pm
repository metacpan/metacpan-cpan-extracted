package Catmandu::Store::OAI;

use Catmandu::Sane;

our $VERSION = '0.19';

use Moo;
use Catmandu::Util qw(:is);
use Catmandu::Importer::OAI;
use Catmandu::Store::OAI::Bag;
use namespace::clean;

with 'Catmandu::Store';

has url             => (is => 'ro', required => 1);
has metadataPrefix  => (is => 'ro', default => sub { "oai_dc" });
has handler         => (is => 'ro', default => sub { "oai_dc" });
has oai             => (is => 'lazy');

sub _build_oai {
    my ($self) = @_;
    Catmandu::Importer::OAI->new(
        url             => $self->url ,
        metadataPrefix  => $self->metadataPrefix ,
        handler         => $self->handler ,
    );
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::OAI - A Catmandu store backed by OAI-PMH

=head1 SYNOPSIS

    # From the command line

    # Export data from OAI
    $ catmandu export OAI --url http://somewhere.org/oai to JSON > data.json

    # Export only one record
    $ catmandu export OAI --url http://somewhere.org/oai --id 1234

    # Export from a set
    $ catmandu export OAI --url http://somewhere.org/oai --bag fulltext

    # From Perl

    use Catmandu;

    my $store = Catmandu->store('OAI', url => ' http://somewhere.org/oai ');

    # All bags are iterators
    $store->bag->each(sub { ... });
    $store->bag->take(10)->each(sub { ... });

    my $rec = $store->bag->get('1234');

=head1 METHODS

=head2 new(url => $url , metadataPrefix => $metadataPrefix , handler => $handler)

Create a new Catmandu::Store::OAI store connected to baseURL $url.

=head1 INHERITED METHODS

This Catmandu::Store implements:

=over 3

=item L<Catmandu::Store>

=back

Each Catmandu::Bag in this Catmandu::Store implements:

=over 3

=item L<Catmandu::Bag>

=back

=head1 SEE ALSO

L<Catmandu::Store> ,
L<Catmandu::Importer::OAI>

=head1 AUTHOR

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
