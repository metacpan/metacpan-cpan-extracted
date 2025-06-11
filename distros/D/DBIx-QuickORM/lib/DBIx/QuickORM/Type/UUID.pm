package DBIx::QuickORM::Type::UUID;
use strict;
use warnings;

our $VERSION = '0.000014';

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Type';

use Scalar::Util qw/blessed/;
use UUID qw/uuid7 parse unparse/;
use Carp qw/croak/;

sub new { uuid7() }

sub qorm_inflate {
    my $in = pop;
    my $class = shift // __PACKAGE__;

    return undef unless defined $in;

    return $class->looks_like_uuid($in) // $class->looks_like_bin($in) // croak "'$in' does not look like a UUID";
}

sub qorm_deflate {
    my $affinity = pop;
    my $in = pop;
    my $class = shift // __PACKAGE__;

    return undef unless defined $in;

    if (my $uuid = $class->looks_like_uuid($in)) {
        return $uuid if $affinity eq 'string';

        my $b;
        parse($in, $b);
        return $b;
    }

    if (my $uuid = $class->looks_like_bin($in)) {
        return $in if $affinity eq 'binary';
        return $uuid;
    }

    croak "'$in' does not look like a uuid";
}

sub qorm_compare {
    my $class = shift;
    my ($a, $b) = @_;

    $a = $class->qorm_inflate($a);
    $b = $class->qorm_inflate($b);

    my $da = defined($a);
    my $db = defined($b);

    return $a cmp $b if $da && $db;
    return 0 unless $da || $db;
    return 1;
}

sub qorm_affinity {
    my $class = shift;
    my %params = @_;

    if (my $sql_type = $params{sql_type}) {
        return 'string' if lc($sql_type) eq 'uuid';
        return 'binary' if $sql_type =~ m/(bin(ary)?|bytea?|blob)/i;
    }

    if (my $dialect = $params{dialect}) {
        return 'string' if $dialect->supports_type('uuid');
    }

    return 'string';
}

sub qorm_sql_type {
    my $self = shift;
    my ($dialect) = @_;

    if (my $stype = $dialect->supports_type('uuid')) {
        return $stype;
    }

    # Document how to set up binary(16)
    # Basically use the post_column hook in Autofill
    return 'VARCHAR(36)';
}

sub looks_like_bin {
    my $in = pop;
    use bytes;
    return undef unless length($in) == 16;
    my $s;
    unparse($in, $s);
    return $s;
}

sub looks_like_uuid {
    my $in = pop;
    return $in if $in && $in =~ m/^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/i;
    return undef;
}

sub qorm_register_type {
    my $self = shift;
    my ($types, $affinities) = @_;

    my $class = ref($self) || $self;

    $types->{uuid} //= $class;

    push @{$affinities->{binary}} => sub {
        my %params = @_;
        return $class if $params{name}    =~ m/uuid/i;
        return $class if $params{db_name} =~ m/uuid/i;
        return;
    };

    push @{$affinities->{string}} => sub {
        my %params = @_;
        return $class if $params{name}    =~ m/uuid/i;
        return $class if $params{db_name} =~ m/uuid/i;
        return;
    };
}

1;
