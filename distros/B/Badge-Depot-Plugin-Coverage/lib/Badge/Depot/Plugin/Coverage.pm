use 5.10.0;
use strict;
use warnings;
use feature qw/say/;

package Badge::Depot::Plugin::Coverage;

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;
use Types::Standard qw/Str Bool Num/;
use Types::URI qw/Uri/;
use JSON::MaybeXS 'decode_json';
use Path::Tiny;
use DateTime;
use DateTime::Format::RFC3339;
with 'Badge::Depot';

# ABSTRACT: Code coverage plugin for Badge::Depot
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0101';

has coverage => (
    is => 'ro',
    isa => Num,
    required => 0,
    predicate => 1,
);
has custom_image_url => (
    is => 'ro',
    isa => Uri,
    coerce => 1,
    default => 'https://img.shields.io/badge/%s-%s-%s.svg',
);
has text => (
    is => 'ro',
    isa => Str,
    default => 'coverage',
);
has max_age => (
    is => 'ro',
    isa => 'Int',
    default => '60',
    documentation => q{Include coverage badge if the latest cover run was done less than 'max_age' minutes ago},
);


sub BUILD {
    my $self = shift;

    my $coverage = $self->determine_coverage;
    if($coverage == -1) {
        $self->log('! Could not determine coverage, skips Coverage badge');
        return;
    }

    $coverage = sprintf '%.1f', $coverage;
    my $color = $self->determine_color($coverage);
    $self->image_url(sprintf $self->custom_image_url, $self->text, $coverage.'%', $color);
    $self->image_alt(sprintf '%s %s', $self->text, $coverage.'%');
    $self->log("Adds coverage badge ($coverage%)");
}


sub determine_coverage {
    my $self = shift;
    return $self->coverage if $self->has_coverage;

    my $log_file = path(qw/. .coverhistory.json/);

    if(!$log_file->exists) {
        $self->log('! Could not find cover history file (.coverhistory.json), no coverage to add');
        return -1;
    }

    my $history = decode_json($log_file->slurp);

    if(!scalar @$history) {
        $self->log('! No coverage history in .coverhistory.json, nothing to add');
        return -1;
    }

    my $summary = $history->[-1];
    my $created_at = DateTime::Format::RFC3339->parse_datetime($summary->{'created_at'});
    my $since = DateTime->now - $created_at;

    my $minutes = $since->years * 1440 * 365
                + $since->months * 1440 * 30
                + $since->days * 1440
                + $since->hours * 60
                + $since->minutes
                + $since->seconds / 60;

    if($minutes > $self->max_age) {
        $self->log("! Latest coverage was run @{[ sprintf '%.1f', $minutes ]} minutes ago, maximum allowed age is @{[ $self->max_age ]} minutes, wont add coverage");
        return -1;
    }
    return $summary->{'total'};
}
sub determine_color {
    my $self = shift;
    my $coverage = shift;

    return $coverage < 75 ? 'red'
         : $coverage < 90 ? 'orange'
         : $coverage < 100 ? 'yellow'
         : $coverage == 100 ? 'brightgreen'
         :                     'blue'
         ;
}
sub log {
    my $self = shift;
    my $text = shift;

    say "[Badge/Coverage] $text";

};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Badge::Depot::Plugin::Coverage - Code coverage plugin for Badge::Depot

=head1 VERSION

Version 0.0101, released 2016-02-17.

=head1 SYNOPSIS

Used standalone:

    use Badge::Depot::Plugin::Coverage;

    my $badge = Badge::Depot::Plugin::Coverage->new(coverage => 87);

    print $badge->to_html;

Used together with L<Pod::Weaver::Section::Badges>, in weaver.ini:

    [Badges]
    ; other settings
    badge = Coverage

=head1 DESCRIPTION

This L<Badge::Depot> badge is meant to be used together with L<Dist::Zilla::App::Command::coverh> (or standalone, as per the synopsis) and creates a coverage badge:

=for HTML <p><img src="https://img.shields.io/badge/coverage-87%-orange.svg" /></p>

=for markdown ![Coverage 87%](https://img.shields.io/badge/coverage-87%-orange.svg)

=head1 ATTRIBUTES

=head2 coverage

Set the code coverage percentage manually. Should only be used when L<Dist::Zilla::App::Command::coverh> is B<not> used.

=head2 custom_image_url

Default: C<https://img.shields.io/badge/%s-%s-%s.svg>

Override the default image url. It is expected to have three C<sprintf> placeholders: Text, coverage percentage and color.

=head2 max_age

Default: C<60>

When used together with L<Dist::Zilla::App::Command::coverh>, only include the badge if the latest coverage run was less than C<max_age> minutes ago.

=head2 text

Default: C<coverage>

Set a different badge text.

=head1 SEE ALSO

=over 4

=item *

L<Badge::Depot>

=item *

L<Task::Badge::Depot>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Badge-Depot-Plugin-Coverage>

=head1 HOMEPAGE

L<https://metacpan.org/release/Badge-Depot-Plugin-Coverage>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
