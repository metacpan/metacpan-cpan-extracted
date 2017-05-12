package Data::Transmute;

our $DATE = '2015-05-05'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(transmute_array transmute_hash);

sub transmute_hash_create_key {
    my %args = @_;

    my $data = $args{data};
    my $name = $args{name};

    if (exists $data->{$name}) {
        return if $args{ignore};
        die "Key '$name' already exists" unless $args{replace};
    }
    $data->{$name} = $args{value};
}

sub transmute_hash_rename_key {
    my %args = @_;

    my $data = $args{data};
    my $from = $args{from};
    my $to   = $args{to};

    if (!exists($data->{$from})) {
        die "Old key '$from' doesn't exist" unless $args{ignore_missing_from};
        return;
    }
    if (exists $data->{$to}) {
        return if $args{ignore_existing_target};
        die "Target key '$from' already exists" unless $args{replace};
    }
    $data->{$to} = $data->{$from};
    delete $data->{$from};
}

sub transmute_hash_delete_key {
    my %args = @_;

    my $data = $args{data};
    my $name = $args{name};

    delete $data->{$name};
}

sub transmute_array {
    no strict 'refs';

    my %args = @_;

    my $data  = $args{data} or die "Please specify data";
    ref($data) eq 'ARRAY' or die "Data must be array";

    my $rules = $args{rules} or die "Please specify rules";

    my $rulenum = 0;
    for my $rule (@$rules) {
        $rulenum++;
        my $funcname = "transmute_array_$rule->[0]";
        die "rule #$rulenum: Unknown function '$rule->[0]'"
            unless defined &{$funcname};
        my $func = \&{$funcname};
        $func->(
            %{$rule->[1] // {}},
            data => $data,
        );
    }
}

sub transmute_hash {
    no strict 'refs';

    my %args = @_;

    my $data  = $args{data} or die "Please specify data";
    ref($data) eq 'HASH' or die "Data must be hash";

    my $rules = $args{rules} or die "Please specify rules";

    my $rulenum = 0;
    for my $rule (@$rules) {
        $rulenum++;
        my $funcname = "transmute_hash_$rule->[0]";
        die "rule #$rulenum: Unknown function '$rule->[0]'"
            unless defined &{$funcname};
        my $func = \&{$funcname};
        $func->(
            %{$rule->[1] // {}},
            data => $data,
        );
    }
}

1;
# ABSTRACT: Transmute (transform) data structure using rules data

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Transmute - Transmute (transform) data structure using rules data

=head1 VERSION

This document describes version 0.02 of Data::Transmute (from Perl distribution Data-Transmute), released on 2015-05-05.

=head1 SYNOPSIS

 use Data::Transmute qw(transmute_array transmute_hash);

 transmute_hash(
     data => \%hash,
     rules => [

         # create a new key, error if key already exists
         [create_key => {name=>'foo', value=>1}],

         # create another key, but this time ignore/noop if key already exists
         # (ignore=1). this is like INSERT IGNORE in SQL.
         [create_key => {name=>'bar', value=>2, ignore=>1}],

         # create yet another key, this time replace existing keys (replace=1).
         # this is like REPLACE INTO in SQL.
         [create_key => {name=>'baz', value=>3, replace=>1}],

         # rename a single key, error if old name doesn't exist or new name
         # exists
         [rename_key => {from=>'qux', to=>'quux'}],

         # rename another key, but this time ignore if old name doesn't exist
         # (ignore=1) or if new name already exists (replace=1)
         [rename_key => {from=>'corge', to=>'grault', ignore_missing_from=>1, replace=>1}],

         # delete a key, will noop if key already doesn't exist
         [delete_key => {name=>'garply'}],

     ],
 );

=head1 DESCRIPTION

B<STATUS: EARLY DEVELOPMENT, SOME FEATURES MIGHT BE MISSING>

This module provides routines to transmute (transform) a data structure in-place
using rules which is another data structure (an arrayref of rule
specifications). It is similar to L<Hash::Transform> except the recipe offers
ability for more complex transformations.

One use-case for this module is to convert/upgrade configuration files.

=for Pod::Coverage ^(transmute_(array|hash)_.+)$

=head1 RULES

Rules is an array of rule specifications.

Each rule specification: [$funcname, \%args]

$funcname is the name of an actual function in L<Data::Transmute> namespace,
with C<transmute_array_> or C<transmute_hash_> prefix removed.

\%args: a special arg will be inserted: C<data>.

=head1 FUNCTIONS

=head2 transmute_array(%args)

Transmute an array, die on failure. Input data is specified in the C<data>
argument, which will be modified in-place (so you'll need to clone it first if
you don't want to modify the original data). Rules is specified in C<rules>
argument.

=head2 transmute_hash(%args)

Transmute a hash, die on failure. Input data is specified in the C<data>
argument, which will be modified in-place (so you'll need to clone it first if
you don't want to modify the original data). Rules is specified in C<rules>
argument.

=head1 TODOS

Check arguments (DZP:Rinci::Wrap?).

Undo?

Function to mass rename keys (by regex substitution, prefix, custom Perl code,
...).

Function to mass delete keys (by regex, prefix, ...).

Specify subrules.

=head1 SEE ALSO

L<Hash::Transform> is similar in concept. It allows transforming a hash using
rules encoded in a hash. However, the rules only allow for simpler
transformations: rename a key, create a key with a specified value, create a key
that from a string-based join of other keys/strings. For more complex needs,
you'll have to supply a coderef to do the transformation yourself manually.
Another thing I find limiting is that the rules is a hash, which means there is
no way to specify order of processing.

L<Config::Model>, which you can also use to convert/upgrade configuration files.
But I find this module slightly too heavyweight for the simpler needs that I
have, hence I created Data::Transmute.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Transmute>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Transmute>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Transmute>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
