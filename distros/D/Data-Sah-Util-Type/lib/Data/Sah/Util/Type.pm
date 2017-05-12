package Data::Sah::Util::Type;

our $DATE = '2016-12-09'; # DATE
our $VERSION = '0.46'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_type is_type is_simple is_numeric is_collection is_ref);

# XXX absorb and use metadata from Data::Sah::Type::*
our $type_metas = {
    all   => {scalar=>0, numeric=>0, ref=>0},
    any   => {scalar=>0, numeric=>0, ref=>0},
    array => {scalar=>0, numeric=>0, ref=>1},
    bool  => {scalar=>1, numeric=>0, ref=>0},
    buf   => {scalar=>1, numeric=>0, ref=>0},
    cistr => {scalar=>1, numeric=>0, ref=>0},
    code  => {scalar=>1, numeric=>0, ref=>1},
    float => {scalar=>1, numeric=>1, ref=>0},
    hash  => {scalar=>0, numeric=>0, ref=>1},
    int   => {scalar=>1, numeric=>1, ref=>0},
    num   => {scalar=>1, numeric=>1, ref=>0},
    obj   => {scalar=>1, numeric=>0, ref=>1},
    re    => {scalar=>1, numeric=>0, ref=>1, simple=>1},
    str   => {scalar=>1, numeric=>0, ref=>0},
    undef => {scalar=>1, numeric=>0, ref=>0},
    date     => {scalar=>1, numeric=>0, ref=>0},
    duration => {scalar=>1, numeric=>0, ref=>0},
};

sub get_type {
    my $sch = shift;

    if (ref($sch) eq 'ARRAY') {
        $sch = $sch->[0];
    }

    if (defined($sch) && !ref($sch)) {
        $sch =~ s/\*\z//;
        return $sch;
    } else {
        return undef;
    }
}

sub _normalize {
    require Data::Sah::Normalize;

    my ($sch, $opts) = @_;
    return $sch if $opts->{schema_is_normalized};
    return Data::Sah::Normalize::normalize_schema($sch);
}

# for any|all to pass a criteria, we assume that all of the schemas in the 'of'
# clause must also pass (and there must not be '!of', 'of&', or that kind of
# thing.
sub _handle_any_all {
    my ($sch, $opts, $crit) = @_;
    $sch = _normalize($sch, $opts);
    return 0 if $sch->[1]{'of.op'};
    my $of = $sch->[1]{of};
    return 0 unless $of && ref($of) eq 'ARRAY' && @$of;
    for (@$of) {
        return 0 unless $crit->($_);
    }
    1;
}

sub is_type {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    $type;
}

sub is_simple {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_simple(shift) });
    }
    return $tmeta->{simple} // ($tmeta->{scalar} && !$tmeta->{ref});
}

sub is_collection {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_collection(shift) });
    }
    return !$tmeta->{scalar};
}

sub is_numeric {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_numeric(shift) });
    }
    return $tmeta->{numeric};
}

sub is_ref {
    my ($sch, $opts) = @_;
    $opts //= {};

    my $type = get_type($sch) or return undef;
    my $tmeta = $type_metas->{$type} or return undef;
    if ($type eq 'any' || $type eq 'all') {
        return _handle_any_all($sch, $opts, sub { is_ref(shift) });
    }
    return $tmeta->{ref};
}

1;
# ABSTRACT: Utility functions related to types

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Util::Type - Utility functions related to types

=head1 VERSION

This document describes version 0.46 of Data::Sah::Util::Type (from Perl distribution Data-Sah-Util-Type), released on 2016-12-09.

=head1 SYNOPSIS

 use Data::Sah::Util::Type qw(
     get_type
     is_type
     is_simple is_numeric is_collection is_ref
 );

 say get_type("int");                          # -> int
 say get_type("int*");                         # -> int
 say get_type([int => min=>0]);                # -> int
 say get_type("foo");                          # -> foo (doesn't check type is known)

 say is_type("int*");                          # -> 1
 say is_type("foo");                           # -> 0

 say is_simple("int");                          # -> 1
 say is_simple("array");                        # -> 0
 say is_simple([any => of => ["float", "str"]); # -> 1
 say is_simple("re");                           # -> 1
 say is_simple("foo");                          # -> 0

 say is_collection("array*");            # -> 1
 say is_collection(["hash", of=>"int"]); # -> 1
 say is_collection("str");               # -> 0
 say is_collection("foo");               # -> 0

 say is_ref("code*"); # -> 1
 say is_ref("array"); # -> 1
 say is_ref("str");   # -> 0
 say is_ref("foo");   # -> 0

 say is_numeric(["int", min=>0]); # -> 1
 say is_numeric("str");           # -> 0
 say is_numeric("foo");           # -> 0

=head1 DESCRIPTION

This module provides some secondary utility functions related to L<Sah> and
L<Data::Sah>. It is deliberately distributed separately from the Data-Sah main
distribution to be differentiated from Data::Sah::Util which contains "primary"
utilities and is distributed with Data-Sah.

Reference table for simple/collection/ref/numeric criteria of builtin types:

 +----------+-----------+---------------+--------+------------+
 | type     | is_simple | is_collection | is_ref | is_numeric |
 +----------+-----------+---------------+--------+------------+
 | array    |           | 1             | 1      |            |
 | bool     | 1         |               |        |            |
 | buf      | 1         |               |        |            |
 | cistr    | 1         |               |        |            |
 | code     |           |               | 1      |            |
 | date     | 1         |               |        |            |
 | duration | 1         |               |        |            |
 | float    | 1         |               |        | 1          |
 | hash     |           | 1             | 1      |            |
 | int      | 1         |               |        | 1          |
 | num      | 1         |               |        | 1          |
 | obj      |           |               | 1      |            |
 | re       | 1         |               | 1      |            |
 | str      | 1         |               |        |            |
 | undef    | 1         |               |        |            |
 +----------+-----------+---------------+--------+------------+

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 get_type($sch) => STR

Return type name.

=head2 is_type($sch) => STR

Return type name if type in schema is known, or undef.

=head2 is_simple($sch[, \%opts]) => BOOL

Simple means "scalar" or can be represented as a scalar. This is currently used
to determine if a builtin type can be specified as an argument or option value
in command-line.

This includes C<re>, C<bool>, as well as C<date> and C<duration>.

If type is C<all>, then for this routine to be true all of the mentioned types
must be simple. If type is C<any>, then for this routine to be true at least one
of the mentioned types must be simple.

Options:

=over

=item * schema_is_normalized => BOOL

=back

=head2 is_collection($sch[, \%opts]) => BOOL

Collection means C<array> or C<hash>.

If type is C<all>, then for this routine to be true all of the mentioned types
must be collection. If type is C<any>, then for this routine to be true at least
one of the mentioned types must be collection.

=head2 is_ref($sch[, \%opts]) => BOOL

"Ref" means generally a reference in Perl. But C<date> and C<duration> are not
regarded as "ref". Regular expression on the other hand is regarded as a ref.

If type is C<all>, then for this routine to be true all of the mentioned types
must be "ref". If type is C<any>, then for this routine to be true at least one
of the mentioned types must be "ref".

=head2 is_numeric($sch[, \%opts]) => BOOL

Currently, only C<num>, C<int>, and C<float> are numeric.

If type is C<all>, then for this routine to be true all of the mentioned types
must be numeric. If type is C<any>, then for this routine to be true at least
one of the mentioned types must be numeric.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Util-Type>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Util-Type>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Util-Type>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
