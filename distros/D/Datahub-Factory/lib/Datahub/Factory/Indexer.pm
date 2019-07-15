package Datahub::Factory::Indexer;

use Datahub::Factory::Sane;

our $VERSION = '1.75';

use Catmandu;
use Moose::Role;
use Catmandu::Util qw(:io);
use namespace::clean;

has out       => (is => 'lazy');
has logger    => (is => 'lazy');
has file_name => (is => 'ro', required => 1);

requires 'index';

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Indexer - Namespace for indexer packages

=head1 SYNOPSIS

    use Datahub::Factory;


=head1 DESCRIPTION


=head1 AUTHORS

Pieter De Praetere <pieter@packed.be>

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

=head1 COPYRIGHT

Copyright 2017 - PACKED vzw, Vlaamse Kunstcollectie vzw

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.

=cut
