package Datahub::Factory::Exporter::Solr;

use Datahub::Factory::Sane;

use Moo;
use Catmandu;
use HTTP::Headers;

with 'Datahub::Factory::Exporter';

has url         => (is => 'ro', required => 1);

sub _build_out {
    my $self = shift;
    my $store = Catmandu->store(
        'Solr',
        url => $self->url
    );

    return $store;
}

sub add {
    my ($self, $item) = @_;
    $self->out->bag->add($item);
    $self->out->bag->commit;
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Exporter::Solr - Export items to a Solr instance

=head1 SYNOPSIS

    use Datahub::Factory;

    my $solr_options = {
        url => 'https://my.solr.org/instance'
    };

    my $exporter = Datahub::Factory->exporter('Solr')->new($solr_options);

    $exporter->add({'id' => 1});

=head1 DESCRIPTION

This module exports items to a Solr instance.

=head1 PARAMETERS

=over

=item C<url>

URL where the Solr instance resides. Required.

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
