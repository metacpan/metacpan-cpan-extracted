use 5.14.0;
use strict;
use warnings;

package Acme::Resume::Moose;

# ABSTRACT: Imports methods and adds attributes
our $VERSION = '0.0109';

use Moose::Exporter;
use Acme::Resume::Types::Job;
use Acme::Resume::Types::Education;

use Types::Standard -types;
use Acme::Resume::Types -types;

Moose::Exporter->setup_import_methods(with_meta => [qw/name email phone address education job/]);

sub name {
    my $meta = shift;
    $meta->add_attribute(name => (
        is => 'ro',
        isa => Str,
        default => shift,
    ));
}
sub email {
    my $meta = shift;
    $meta->add_attribute(email => (
        is => 'ro',
        isa => Str,
        default => shift,
    ));
}
sub phone {
    my $meta = shift;
    $meta->add_attribute(phone => (
        is => 'ro',
        isa => Str,
        default => shift,
    ));
}
sub address {
    my $meta = shift;
    my $address = shift;

    $meta->add_attribute(address => (
        is => 'ro',
        isa => ArrayRef[Str],
        default => sub { $address },
        traits => ['Array'],
        handles => {
            add_address => 'push',
            full_address => 'elements',
            has_address => 'count',
            get_address => 'get',
            join_address => 'join',
        },
    ));
}

sub education {
    my $meta = shift;
    my $education = shift;

    my $current_educations = [];

    if($meta->has_attribute('educations')) {
        push @$current_educations => @{ $meta->get_attribute('educations')->default->() };
        $meta->remove_attribute('educations');
    }

    push @{ $current_educations } => Acme::Resume::Types::Education->new(%{ $education });

    $meta->add_attribute(educations => (
        is => 'ro',
        isa => Educations,
        traits => ['Array'],
        default => sub { $current_educations },
        coerce => 1,
        handles => {
            add_education => 'push',
            all_educations => 'elements',
            has_education => 'count',
            get_education => 'get',
        },
    ));
}

sub job {
    my $meta = shift;
    my $job = shift;

    my $current_jobs = [];

    if($meta->has_attribute('jobs')) {
        push @$current_jobs => @{ $meta->get_attribute('jobs')->default->() };
        $meta->remove_attribute('jobs');
    }

    push @{ $current_jobs } => Acme::Resume::Types::Job->new(%{ $job });

    $meta->add_attribute(jobs => (
        is => 'ro',
        isa => Jobs,
        traits => ['Array'],
        default => sub { $current_jobs },
        coerce => 1,
        handles => {
            add_job => 'push',
            all_jobs => 'elements',
            has_job_history => 'count',
            get_job => 'get',
        },
    ));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Resume::Moose - Imports methods and adds attributes

=head1 VERSION

Version 0.0109, released 2022-01-30.

=head1 SOURCE

L<https://github.com/Csson/p5-Acme-Resume>

=head1 HOMEPAGE

L<https://metacpan.org/release/Acme-Resume>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
