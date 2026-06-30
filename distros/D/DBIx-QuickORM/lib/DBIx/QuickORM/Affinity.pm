package DBIx::QuickORM::Affinity;
use strict;
use warnings;

our $VERSION = '0.000026';

use Carp qw/croak/;

use parent 'Exporter';
our @EXPORT = qw{
    valid_affinities
    validate_affinity
    compare_affinity_values
    affinity_from_type
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Affinity - Column affinity helpers for DBIx::QuickORM.

=head1 DESCRIPTION

Functions for working with column "affinities" - the broad value categories
(C<string>, C<numeric>, C<binary>, C<boolean>) that drive type-aware
comparison and introspection. Maps SQL type names to affinities, validates
affinity names, and compares two values according to a given affinity.

All four functions are exported by default.

=head1 SYNOPSIS

    use DBIx::QuickORM::Affinity;

    my @all      = valid_affinities();
    my $affinity = affinity_from_type('VARCHAR(255)');   # 'string'
    my $ok       = validate_affinity('numeric');         # 'numeric'

    my $same = compare_affinity_values('numeric', 1, 1.0);

=cut

my %VALID_AFFINITY = (
    string  => 'string',
    numeric => 'numeric',
    binary  => 'binary',
    boolean => 'boolean',
);

sub valid_affinities  { my %seen; sort grep { !$seen{$_}++ } values %VALID_AFFINITY }

sub validate_affinity { my $affinity = pop or return; return $VALID_AFFINITY{$affinity} }

sub compare_affinity_values {
    my ($valb, $vala, $affinity, $class_or_self) = reverse @_;

    croak "'affinity' is required" unless $affinity;
    croak "'$affinity' is not a valid affinity" unless $VALID_AFFINITY{$affinity};

    # For boolean undef is false, so we do not do the undef check until after
    # this. The result is "true if equal" to match the other affinities: two
    # values are equal when their truthiness agrees.
    return !($vala xor $valb) if $affinity eq 'boolean';

    # Both undef means equal
    return 1 if !defined($vala) && !defined($valb);

    # For the rest of these it is false if only 1 of the 2 is defined
    return 0 if (defined($vala) xor defined($valb));

    return ($vala eq $valb) if $affinity eq 'string';
    return ($vala == $valb) if $affinity eq 'numeric';

    # I am sceptical about 'eq' here. Are there places where 2 strings may
    # compare as equal because of encodings or other stuff, even when the
    # binary data is different? According to #perl everyone says no, so I can
    # just use 'eq'.
    return ($vala eq $valb) if $affinity eq 'binary';

    croak "Comparison for affinity '$affinity' fell off the end. Please file a bug report.";
}

my %AFFINITY_BY_TYPE = (
    # Stringy
    char   => 'string',
    json   => 'string',
    string => 'string',
    text   => 'string',
    bpchar => 'string',

    # Special
    enum  => 'string',
    jsonb => 'string',
    money => 'string',
    set   => 'string',
    uuid  => 'string',

    # Binary
    binary => 'binary',
    blob   => 'binary',
    bytea  => 'binary',

    # Numeric
    'double precision' => 'numeric',

    bit     => 'numeric',
    dec     => 'numeric',
    decimal => 'numeric',
    double  => 'numeric',
    float   => 'numeric',
    int     => 'numeric',
    integer => 'numeric',
    number  => 'numeric',
    numeric => 'numeric',
    real    => 'numeric',
    serial  => 'numeric',

    # Date/Time
    date        => 'string',
    day         => 'string',
    interval    => 'string',
    stamp       => 'string',
    time        => 'string',
    timestamp   => 'string',
    timestamptz => 'string',
    year        => 'string',

    # Boolean
    bool    => 'boolean',
    boolean => 'boolean',
);

sub affinity_from_type {
    my $type = pop or return undef;

    $type = lc($type);
    $type =~ s/\s*\(.*\)\s*$//;
    $type =~ s/^\s+//;
    $type =~ s/\s+$//;

    if ($type =~ m/^(?:tiny|medium|big|long|var)(.+)/i) {
        return $AFFINITY_BY_TYPE{$1} if $AFFINITY_BY_TYPE{$1};
    }

    return $AFFINITY_BY_TYPE{$type} // undef;
}

1;

__END__

=head1 EXPORTS

=over 4

=item @affinities = valid_affinities()

Returns the sorted, de-duplicated list of valid affinity names.

=item $affinity_or_undef = validate_affinity($affinity)

Returns the affinity name if it is valid, otherwise returns nothing.

=item $bool = compare_affinity_values($affinity, $a, $b)

Compares two values under the given affinity and returns true when they are
considered equal. For C<boolean>, undef is treated as false; for the other
affinities two undefs compare equal and a defined/undef mismatch is unequal.
Croaks when C<$affinity> is missing or not valid.

=item $affinity_or_undef = affinity_from_type($type)

Maps a SQL type name to an affinity. Lower-cases the type, strips any
parenthesized size/precision, and resolves common C<tiny>/C<medium>/C<big>/
C<long>/C<var> prefixes. Returns undef for unknown types.

=back

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
