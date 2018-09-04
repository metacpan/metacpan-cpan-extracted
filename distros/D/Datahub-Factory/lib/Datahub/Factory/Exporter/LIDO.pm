package Datahub::Factory::Exporter::LIDO;

use Datahub::Factory::Sane;

our $VERSION = '1.74';

use Moo;
use Catmandu;
use namespace::clean;

has file_name => (is => 'ro');

with 'Datahub::Factory::Exporter';

sub _build_out {
    my $self = shift;
    my $exporter;
    if (defined($self->file_name)) {
        $exporter = Catmandu->exporter('LIDO', file => $self->file_name);
    } else {
        $exporter = Catmandu->exporter('LIDO');
    }
    return $exporter;
}

sub add {
    my ($self, $item) = @_;
    $self->out->add($item);
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Exporter::LIDO - Export items to LIDO

=head1 SYNOPSIS

    use Datahub::Factory;

    my $exporter = Datahub::Factory->exporter('LIDO')->new();

    $exporter->add({'id' => 1});

=head1 DESCRIPTION

Convert records to LIDO XML and send them to STDOUT. The records are
convert as-is; any fixes must be done beforehand.

=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2017 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut

