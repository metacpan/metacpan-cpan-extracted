package Datahub::Factory::Exporter;

use Datahub::Factory::Sane;

our $VERSION = '1.71';

use Catmandu;
use Moose::Role;
use Catmandu::Util qw(:io);
use namespace::clean;

has out => (
    is  => 'lazy'
);

requires 'add';

has logger    => (is => 'lazy');

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Exporter - Namespace for exporter packages

=head1 SYNOPSIS

    use Datahub::Factory;

    my $datahub_options = {
        datahub_url         => 'https://www.datahub.be',
        oauth_client_id     => 'mydatahub',
        oauth_client_secret => 'thedatahub',
        oauth_username      => 'datahub',
        oauth_password      => 'adatahub'
    };

    my $exporter = Datahub::Factory->exporter('Datahub')->new($datahub_options);

    $exporter->add({'id' => 1});

=head1 DESCRIPTION

A Datahub::Factory::Exporter is a package that is used as a L<role|Moose::Role> for packages
that export data to an endpoint. It enforces a generic reusable interface so
different packages can be loaded and executed programmatically.

=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2017 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
