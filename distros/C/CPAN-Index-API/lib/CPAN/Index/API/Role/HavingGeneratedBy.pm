package CPAN::Index::API::Role::HavingGeneratedBy;

our $VERSION = '0.008';

use strict;
use warnings;

use Moose::Role;

has generated_by => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

has last_generated => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_generated_by {
    my $package = blessed shift;
    return $package . " " . $package->VERSION;
}

sub _build_last_generated {
    return scalar gmtime() . " GMT";
}

1;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Index::Role::HavingGeneratedBy - Provides 'generated_by' and 'last_generated' attributes

=head1 PROVIDES

=head2 generated_by

Name of software that generated the file.

=head2 last_generated

Date and time when the file was last generated.

=cut
