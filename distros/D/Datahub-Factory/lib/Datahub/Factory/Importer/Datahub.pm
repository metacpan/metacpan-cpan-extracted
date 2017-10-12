package Datahub::Factory::Importer::Datahub;

use Datahub::Factory::Sane;

our $VERSION = '1.72';

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Importer';

has datahub_url         => (is => 'ro', required => 1);
has oauth_client_id     => (is => 'ro', required => 1);
has oauth_client_secret => (is => 'ro', required => 1);
has oauth_username      => (is => 'ro', required => 1);
has oauth_password      => (is => 'ro', required => 1);

sub _build_importer {
    my $self = shift;
    my $d = Catmandu->store('Datahub',
        url           => $self->datahub_url,
        client_id     => $self->oauth_client_id,
        client_secret => $self->oauth_client_secret,
        username      => $self->oauth_username,
        password      => $self->oauth_password
    );
    return $d->bag;
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer::Datahub - Import items from a Datahub instance

=head1 SYNOPSIS

    use Datahub::Factory;

    my $datahub_options = {
        datahub_url         => 'https://www.datahub.be',
        oauth_client_id     => 'mydatahub',
        oauth_client_secret => 'thedatahub',
        oauth_username      => 'datahub',
        oauth_password      => 'adatahub'
    };

    my $importer = Datahub::Factory->importer('Datahub')->new($datahub_options);

    $importer->importer->each(sub {
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

This module imports records from a L<Datahub instance|https://github.com/thedatahub/Datahub>.

=head1 PARAMETERS

=over

=item C<datahub_url>

URL where the Datahub resides. This URL is the base URL of the datahub, not
the API url. The module will create the correct API URL automatically. Required.

=item C<oauth_client_id>

OAuth 2 client ID. Required.

=item C<oauth_client_secret>

OAuth2 client secret. Required.

=item C<oauth_username>

Datahub username. Required.

=item C<oauth_password>

Datahub password. Required.

=back

=head1 ATTRIBUTES

=over

=item C<importer>

A L<Importer|Catmandu::Importer> that can be used in your script.

=back

=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2017 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
