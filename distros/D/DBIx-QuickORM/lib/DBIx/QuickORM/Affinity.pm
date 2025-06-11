package DBIx::QuickORM::Affinity;
use strict;
use warnings;

our $VERSION = '0.000014';

use Carp qw/croak/;

use base 'Exporter';
our @EXPORT = qw{
    valid_affinities
    validate_affinity
    compare_affinity_values
    affinity_from_type
};

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
    # this
    return ($vala xor $valb) if $affinity eq 'boolean';

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

    if ($type =~ m/^(?:tiny|medium|big|long|var)(.+)/i) {
        return $AFFINITY_BY_TYPE{$1} if $AFFINITY_BY_TYPE{$1};
    }

    return $AFFINITY_BY_TYPE{$type} // undef;
}

1;
