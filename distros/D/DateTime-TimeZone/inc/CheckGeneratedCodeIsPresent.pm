package CheckGeneratedCodeIsPresent;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

with 'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::FileFinderUser' =>
    { default_finders => [':InstallModules'] };

sub after_build {
    my $self = shift;

    my %found = map { $_->name => 1 } @{ $self->found_files };
    die 'Is the generated code missing?'
        unless $found{'lib/DateTime/TimeZone/Catalog.pm'}
        && $found{'lib/DateTime/TimeZone/America/Chicago.pm'};

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
