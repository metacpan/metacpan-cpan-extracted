package Data::Transmute;

our $DATE = '2019-07-24'; # DATE
our $VERSION = '0.030'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(transmute_data reverse_rules);

sub _rule_create_hash_key {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';
    my $name = $args{name};

    if (exists $data->{$name}) {
        return if $args{ignore};
        die "Key '$name' already exists" unless $args{replace};
    }
    $data->{$name} = $args{value};
}

sub _rulereverse_create_hash_key {
    my %args = @_;
    [delete_hash_key => {name=>$args{name}}];
}

sub _rule_rename_hash_key {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';
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

sub _rulereverse_rename_hash_key {
    my %args = @_;
    # XXX replace can't really be reversed
    [rename_hash_key => {
        from=>$args{to}, to=>$args{from},
        (ignore_missing_from    => $args{ignore_missing_from}   ) x !!defined($args{ignore_missing_from}),
        (ignore_existing_target => $args{ignore_existing_target}) x !!defined($args{ignore_existing_target}),
    }];
}

sub _rule_delete_hash_key {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';
    my $name = $args{name};

    delete $data->{$name};
}

sub _rulereverse_delete_hash_key {
    die "Can't create a reverse for delete_hash_key rule";
}

sub _rule_transmute_array_elems {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'ARRAY';

    for my $el (@$data) {
        $el = transmute_data(
            data => $el,
            rules => $args{rules},
        );
    }
    $data;
}

sub _rulereverse_transmute_array_elems {
    my %args = @_;

    [transmute_array_elems => {
        rules => reverse_rules(rules => $args{rules}),
    }];
}

sub _rule_transmute_hash_values {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';

    for my $k (keys %$data) {
        $data->{$k} = transmute_data(
            data => $data->{$k},
            rules => $args{rules},
        );
    }
    $data;
}

sub _rulereverse_transmute_hash_values {
    my %args = @_;

    [transmute_hash_values => {
        rules => reverse_rules(rules => $args{rules}),
    }];
}

sub transmute_data {
    no strict 'refs';

    my %args = @_;

    exists $args{data} or die "Please specify data";
    my $data  = $args{data};
    my $rules = $args{rules} or die "Please specify rules";

    my $rulenum = 0;
    for my $rule (@$rules) {
        $rulenum++;
        my $funcname = "_rule_$rule->[0]";
        die "rule #$rulenum: Unknown function '$rule->[0]'"
            unless defined &{$funcname};
        my $func = \&{$funcname};
        $func->(
            %{$rule->[1] // {}},
            data => $data,
        );
    }
    $data;
}

sub reverse_rules {
    no strict 'refs';

    my %args = @_;

    my @rev_rules;
    for my $rule (@{ $args{rules} }) {
        my $funcname = "_rulereverse_$rule->[0]";
        my $func = \&{$funcname};
        unshift @rev_rules, $func->(
            %{$rule->[1] // {}},
        );
    }
    \@rev_rules;
}

1;
# ABSTRACT: Transmute (transform) data structure using rules data

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Transmute - Transmute (transform) data structure using rules data

=head1 VERSION

This document describes version 0.030 of Data::Transmute (from Perl distribution Data-Transmute), released on 2019-07-24.

=head1 SYNOPSIS

 use Data::Transmute qw(
     transmute_data
     reverse_rules
 );

 transmute_data(
     data => \@data,
     rules => [


         # this rule only applies when data is a hash, when data is not a hash
         # this will will do nothing. create a single new hash key, error if key
         # already exists.
         [create_hash_key => {name=>'foo', value=>1}],

         # create another hash key, but this time ignore/noop if key already
         # exists (ignore=1). this is like INSERT IGNORE in SQL.
         [create_hash_key => {name=>'bar', value=>2, ignore=>1}],

         # create yet another key, this time replace existing keys (replace=1).
         # this is like REPLACE INTO in SQL.
         [create_hash_key => {name=>'baz', value=>3, replace=>1}],


         # this rule only applies when data is a hash, when data is not a hash
         # this will will do nothing. rename a single key, error if old name
         # doesn't exist or new name exists.
         [rename_hash_key => {from=>'qux', to=>'quux'}],

         # rename another key, but this time ignore if old name doesn't exist
         # (ignore=1) or if new name already exists (replace=1)
         [rename_hash_key => {from=>'corge', to=>'grault', ignore_missing_from=>1, replace=>1}],


         # this rule only applies when data is a hash, when data is not a hash
         # this will will do nothing. delete a single key, will noop if key
         # already doesn't exist.
         [delete_hash_key => {name=>'garply'}],


         # this rule only applies when data is an arrayref, when data is not a
         # array this will will do nothing. for each array element, apply
         # transmute rules to it.
         [transmute_array_elems => {rules => [...]}],


         # this rule only applies when data is a hashref, when data is not a
         # hash this will will do nothing. for each hash value, apply transmute
         # rules to it.
         [transmute_hash_values => {rules => [...]}],


     ],
 );

=head1 DESCRIPTION

This module provides routines to transmute (transform) a data structure in-place
using rules which is another data structure (an arrayref of rule
specifications).

One use-case for this module is to convert/upgrade configuration files.

=head1 RULES

Rules is an array of rule specifications.

Each rule specification: [$funcname, \%args]

\%args: a special arg will be inserted: C<data>.

=head1 FUNCTIONS

=head2 transmute_data

Usage:

 $data = transmute_data(%args)

Transmute data structure, die on failure. Input data is specified in the C<data>
argument, which will be modified in-place (so you'll need to clone it first if
you don't want to modify the original data). Rules is specified in C<rules>
argument.

=head2 reverse_rules

Usage:

 my $reverse_rules = reverse_rules(rules => [...]);

Create a reverse rules, die on failure.

=head1 TODOS

Check arguments (DZP:Rinci::Wrap?).

Undo?

Function to mass rename keys (by regex substitution, prefix, custom Perl code,
...).

Function to mass delete keys (by regex, prefix, ...).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Transmute>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Transmute>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Transmute>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Hash::Transform> is similar in concept. It allows transforming a hash using
rules encoded in a hash. However, the rules only allow for simpler
transformations: rename a key, create a key with a specified value, create a key
that from a string-based join of other keys/strings. For more complex needs,
you'll have to supply a coderef to do the transformation yourself manually.
Another thing I find limiting is that the rules is a hash, which means there is
no way to specify order of processing. And of course, you cannot transform
non-hash data.

L<Config::Model>, which you can also use to convert/upgrade configuration files.
But I find this module slightly too heavyweight for the simpler needs that I
have, hence I created Data::Transmute.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
