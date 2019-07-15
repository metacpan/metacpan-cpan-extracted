package Datahub::Factory::Fixer;

use Datahub::Factory::Sane;

our $VERSION = '1.75';

use Catmandu;
use Moose::Role;
use namespace::clean;

has fixer  => (is => 'lazy');
has logger => (is => 'lazy');

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

1;

__END__

=encoding utf-8

=head1 NAME

Datahub::Factory::Fixer - Namespace for fixer packages

=head1 SYNOPSIS

    use Datahub::Factory;

    my $fixer_options = {
        file_name => '/tmp/my.fix'
    };

    my $exporter = Datahub::Factory->fixer('Fix')->new($fixer_options);

    $fixer->fixer->fix({'id' => 1});

=head1 DESCRIPTION

A Datahub::Factory::Fixer is a package that is used as a L<role|Moose::Role> for packages
that execute fixes on records. It enforces a generic reusable interface so
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
