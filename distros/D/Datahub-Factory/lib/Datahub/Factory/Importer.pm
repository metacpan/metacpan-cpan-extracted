package Datahub::Factory::Importer;

use Datahub::Factory::Sane;

our $VERSION = '1.71';

use Catmandu;
use Moose::Role;
use Try::Tiny;
use namespace::clean;

has importer => (is  => 'lazy');
has logger   => (is => 'lazy');

after _build_importer => sub { };

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

# Do the same for exporter
sub each {
    my ($self, $callback) = @_;
    try {
        return $self->importer->each($callback);
    } catch {
        my $error_msg;
        if ($_->can('message')) {
            $error_msg = sprintf('Fatal error while executing import: %s', $_->message);
        } else {
            $error_msg = sprintf('Fatal error while executing import: %s', $_);
        }
        $self->logger->fatal($error_msg);
        exit 1;
    };
}


1;
__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Importer - Namespace for importer packages

=head1 SYNOPSIS

    use Datahub::Factory;
    use Data::Dumper qw(Dumper);

    my $importer_options = {
        endpoint => 'https://my.oai.org/oai'
    };

    my $importer = Datahub::Factory->importer('OAI')->new($importer_options);

    $importer->importer->each({
        my $item = shift;
        print Dumper($item);
    });

=head1 DESCRIPTION

A Datahub::Factory::Importer is a package that is used as a L<role|Moose::Role> for packages
that import records. It enforces a generic reusable interface so
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
