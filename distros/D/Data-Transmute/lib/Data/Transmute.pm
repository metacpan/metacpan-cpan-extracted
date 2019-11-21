package Data::Transmute;

our $DATE = '2019-10-10'; # DATE
our $VERSION = '0.036'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(transmute_data reverse_rules);

sub _rule_create_hash_key {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';
    my $name = $args{name};
    die "Rule create_hash_key: Please specify 'name'" unless defined $name;

    if (exists $data->{$name}) {
        return if $args{ignore};
        die "Rule create_hash_key: Key '$name' already exists" unless $args{replace};
    }
    die "Rule create_hash_key: Please specify 'value'" unless exists $args{value};
    $data->{$name} = $args{value};
}

sub _rulereverse_create_hash_key {
    my %args = @_;
    die "Cannot generate reverse rule create_hash_key with ignore=1"  if $args{ignore};
    die "Cannot generate reverse rule create_hash_key with replace=1" if $args{replace};
    [delete_hash_key => {name=>$args{name}}];
}

sub _rule_rename_hash_key {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';
    my $from = $args{from};
    die "Rule rename_hash_key: Please specify 'from'" unless defined $from;
    my $to   = $args{to};
    die "Rule rename_hash_key: Please specify 'to'" unless defined $to;

    # noop
    return if $from eq $to;

    if (!exists($data->{$from})) {
        die "Rule rename_hash_key: Can't rename '$from' -> '$to': Old key '$from' doesn't exist" unless $args{ignore_missing_from};
        return;
    }
    if (exists $data->{$to}) {
        return if $args{ignore_existing_target};
        die "Rule rename_hash_key: Can't rename '$from' -> '$to': Target key '$from' already exists" unless $args{replace};
    }
    $data->{$to} = delete $data->{$from};
}

sub _rulereverse_rename_hash_key {
    my %args = @_;
    die "Cannot generate reverse rule rename_hash_key with ignore_missing_from=1"     if $args{ignore_missing_from};
    die "Cannot generate reverse rule rename_hash_key with ignore_existing_target=1"  if $args{ignore_existing_target};
    die "Cannot generate reverse rule rename_hash_key with replace=1"                 if $args{replace};
    [rename_hash_key => {
        from=>$args{to}, to=>$args{from},
    }];
}

sub _rule_modify_hash_value {
    require Data::Cmp;

    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';
    my $name = $args{name};
    die "Rule modify_hash_value: Please specify 'name' (key)" unless defined $name;
    my $from = $args{from};
    my $from_exists = exists $args{from};
    my $to   = $args{to};
    die "Rule rename_hash_key: Please specify 'to'" unless exists $args{to};

    my $errprefix = "Rule modify_hash_value: Can't modify key '$name'".
        ($from_exists ? " from '".($from // '<undef>') : "").
        "' to '".($to // '<undef>')."'";

    unless (exists $data->{$name}) {
        die "$errprefix: key does not exist";
    }

    my $cur = $data->{$name};

    if ($from_exists) {
        # noop
        return unless Data::Cmp::cmp_data($from, $to);

        if (Data::Cmp::cmp_data($cur, $from)) {
            die "$errprefix: current value is not '".($cur // '<undef>')."'";
        }
    }

    $data->{$name} = $to;
}

sub _rulereverse_modify_hash_value {
    my %args = @_;
    die "Cannot generate reverse rule modify_hash_value without from" unless exists $args{from};
    [modify_hash_value => {
        name => $args{name}, from => $args{to}, to => $args{from},
    }];
}

sub _rule_delete_hash_key {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';
    my $name = $args{name};
    die "Rule delete_hash_key: Please specify 'name'" unless defined $name;

    delete $data->{$name};
}

sub _rulereverse_delete_hash_key {
    die "Can't create reverse rule for delete_hash_key";
}

sub _rule_transmute_array_elems {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'ARRAY';

    die "Rule transmute_array_elems: Please specify 'rules' or 'rules_module'"
        unless defined($args{rules}) || defined($args{rules_module});

    my $idx = -1;
  ELEM:
    for my $el (@$data) {
        $idx++;
        if (defined $args{index_is}) {
            next ELEM unless $idx == $args{index_is};
        }
        if (defined $args{index_in}) {
            next ELEM unless grep { $idx == $_ } @{ $args{index_in} };
        }
        if (defined $args{index_match}) {
            next ELEM unless $idx =~ $args{index_match};
        }
        if (defined $args{index_filter}) {
            next ELEM unless $args{index_filter}->(index=>$idx, array=>$data, rules=>$args{rules});
        }
        $el = transmute_data(
            data => $el,
            (rules        => $args{rules})        x !!(exists $args{rules}),
            (rules_module => $args{rules_module}) x !!(exists $args{rules_module}),
        );
    }
    $data;
}

sub _rulereverse_transmute_array_elems {
    my %args = @_;

    [transmute_array_elems => {
        rules => reverse_rules(
            (rules        => $args{rules})        x !!(exists $args{rules}),
            (rules_module => $args{rules_module}) x !!(exists $args{rules_module}),
        ),
        (index_is     => $args{index_is})     x !!(exists $args{index_is}),
        (index_in     => $args{index_in})     x !!(exists $args{index_in}),
        (index_match  => $args{index_match})  x !!(exists $args{index_match}),
        (index_filter => $args{index_filter}) x !!(exists $args{index_filter}),
    }];
}

sub _rule_transmute_hash_values {
    my %args = @_;

    my $data = $args{data};
    return unless ref $data eq 'HASH';

    die "Rule transmute_hash_values: Please specify 'rules' or 'rules_module'"
        unless defined($args{rules}) || defined($args{rules_module});

  KEY:
    for my $key (keys %$data) {
        if (defined $args{key_is}) {
            next KEY unless $key eq $args{key_is};
        }
        if (defined $args{key_in}) {
            next KEY unless grep { $key eq $_ } @{ $args{key_in} };
        }
        if (defined $args{key_match}) {
            next KEY unless $key =~ $args{key_match};
        }
        if (defined $args{key_filter}) {
            next KEY unless $args{key_filter}->(key=>$key, hash=>$data, rules=>$args{rules});
        }
        $data->{$key} = transmute_data(
            data => $data->{$key},
            (rules        => $args{rules})        x !!(exists $args{rules}),
            (rules_module => $args{rules_module}) x !!(exists $args{rules_module}),
        );
    }
    $data;
}

sub _rulereverse_transmute_hash_values {
    my %args = @_;

    [transmute_hash_values => {
        rules => reverse_rules(
            (rules        => $args{rules})        x !!(exists $args{rules}),
            (rules_module => $args{rules_module}) x !!(exists $args{rules_module}),
        ),
        (key_is     => $args{key_is})     x !!(exists $args{key_is}),
        (key_in     => $args{key_in})     x !!(exists $args{key_in}),
        (key_match  => $args{key_match})  x !!(exists $args{key_match}),
        (key_filter => $args{key_filter}) x !!(exists $args{key_filter}),
    }];
}

sub _rules_or_rules_module {
    my $args = shift;

    my $rules = $args->{rules};
    if (!$rules) {
        if (defined $args->{rules_module}) {
            my $mod = "Data::Transmute::Rules::$args->{rules_module}";
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            $rules = \@{"$mod\::RULES"};
        }
    }
    $rules or die "Please specify rules (or rules_module)";
    $rules;
}

sub transmute_data {
    my %args = @_;

    exists $args{data} or die "Please specify data";
    my $data  = $args{data};
    my $rules = _rules_or_rules_module(\%args);

    my $rulenum = 0;
    for my $rule (@$rules) {
        $rulenum++;
        if ($ENV{LOG_DATA_TRANSMUTE_STEP}) {
            log_trace "transmute_data #%d/%d: %s",
                $rulenum, scalar(@$rules), $rule;
        }
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
    my %args = @_;

    my $rules = _rules_or_rules_module(\%args);

    my @rev_rules;
    for my $rule (@$rules) {
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

This document describes version 0.036 of Data::Transmute (from Perl distribution Data-Transmute), released on 2019-10-10.

=head1 SYNOPSIS

 use Data::Transmute qw(
     transmute_data
     reverse_rules
 );

 my $transmuted_data = transmute_data(
     data => \@data,
     rules => [

         # CREATING HASH KEY

         # this rule only applies when data is a hash, when data is not a hash
         # this will do nothing. create a single new hash key, error if key
         # already exists.
         [create_hash_key => {name=>'foo', value=>1}],

         # create another hash key, but this time ignore/noop if key already
         # exists (ignore=1). this is like INSERT IGNORE in SQL.
         [create_hash_key => {name=>'bar', value=>2, ignore=>1}],

         # create yet another key, this time replace existing keys (replace=1).
         # this is like REPLACE INTO in SQL.
         [create_hash_key => {name=>'baz', value=>3, replace=>1}],


         # RENAMING HASH KEY

         # this rule only applies when data is a hash, when data is not a hash
         # this will do nothing. rename a single key, error if old name doesn't
         # exist or new name exists.
         [rename_hash_key => {from=>'qux', to=>'quux'}],

         # rename another key, but this time ignore if old name doesn't exist
         # (ignore=1) or if new name already exists (replace=1)
         [rename_hash_key => {from=>'corge', to=>'grault', ignore_missing_from=>1, replace=>1}],


         # DELETING HASH KEY

         # this rule only applies when data is a hash, when data is not a hash
         # this will do nothing. delete a single key, will noop if key already
         # doesn't exist.
         [delete_hash_key => {name=>'garply'}],


         # APPLYING (SUB)RULES TO ARRAY ELEMENTS

         # this rule only applies when data is an arrayref, when data is not an
         # array this will do nothing. for each array element, apply transmute
         # rules to it.
         [transmute_array_elems => {rules => [...]}],

         # you can select only certain elements to transmute by using one+ of:
         # index_is, index_in, index_match, index_filter.
         [transmute_array_elems => {
              #index_is => 1,              # only transmute 2nd element (index is 0-based)
              #index_in => [0,1,2],        # only transmute the first 3 elements
              #index_match => qr/.../,     # only transmute elements where the index matches a regex
              #index_filter => sub{...},   # only transmute elements where $filter->(index=>$index) returns true
              rules => [...],
          }],


         # APPLYING (SUB)RULES TO HASH VALUES

         # this rule only applies when data is a hashref, when data is not a
         # hash this will do nothing. for each hash value, apply transmute rules
         # to it.
         [transmute_hash_values => {rules => [...]}],

         # you can select only certain keys to transmute by using one+ of:
         # key_is, key_in, key_match, key_filter.
         [transmute_hash_values => {
              #key_is => 'foo',          # only transmute value of key 'foo'
              #key_in => ['foo', 'bar'], # only transmute value of keys 'foo', 'bar'
              #key_match => qr/.../,     # only transmute value of keys that match a regex
              #key_filter => sub{...},   # only transmute value of keys where $filter->(key=>$key) returns true
              rules => [...],
          }],

     ],
 );

You can also load rules from a C<Data::Transmute::Rules::*> module:

 transmute_data(
     data => $data,
     rules_module => 'Convert_Proj1_Data_To_Proj2', # will load Data::Transmute::Rules::Convert_Proj1_Data_To_Proj2 and read its @RULES package variable
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

=head2 create_hash_key

This rule only applies when data is a hash, when data is not a hash this will do
nothing. Create a single new hash key, error if key already exists.

Known arguments (C<*> means required):

=over

=item * name*

=item * value*

=item * ignore

Bool. If set to true, will ignore/noop if key already exists. This is like
INSERT IGNORE (INSERT OR IGNORE) in SQL.

=item * replace

Bool. If set to true, will replace existing keys. This is like REPLACE INTO in
SQL.

=back

=head2 rename_hash_key

This rule only applies when data is a hash, when data is not a hash this will do
nothing. Rename a single key, error if old name doesn't exist or new name
exists.

Known arguments (C<*> means required):

=over

=item * from*

=item * to*

=item * ignore_missing_from

Bool. If set to true, will noop (instead of error) if old name doesn't exist.

=item * replace

Bool. If set to true, will overwrite (instead of error) when target key already
exists.

=back

=head2 modify_hash_value

This rule only applies when data is a hash, when data is not a hash this will do
nothing. Modify a single hash value from original value I<from> to new value
I<to>. Key must exist, and value must originally be I<from>.

Known arguments (C<*> means required):

=over

=item * name*

String. Key name.

=item * from*

String or undef. Original value.

=item * to*

String or undef. New value.

=back

=head2 delete_hash_key

This rule only applies when data is a hash, when data is not a hash this will do
nothing. Delete a single key, will noop if key already doesn't exist.

Known arguments (C<*> means required):

=over

=item * name*

=back

=head2 transmute_array_elems

This rule only applies when data is an arrayref, when data is not an array this
will do nothing. for each array element, apply transmute rules to it.

Known arguments (C<*> means required):

=over

=item * rules

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

=item * rules_module

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

=item * index_is

=item * index_in

=item * index_match

=item * index_filter

Coderef. Only transmute elements where $coderef->(index=>$index) is true. Aside
from C<index>, the coderef will also receive these arguments: C<rules> (the
rule), C<array> (the array).

=back

=head2 transmute_hash_values

This rule only applies when data is a hashref, when data is not a hash this will
do nothing. For each hash value, apply transmute rules to it.

Known arguments (C<*> means required):

=over

=item * rules

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

=item * rules_module

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

=item * key_is

=item * key_in

=item * key_match

=item * key_filter

Coderef. Only transmute value of keys where $coderef->(key=>$key) is true. Aside
from C<key>, the coderef will also receive these arguments: C<rules> (the rule),
C<hash> (the hash).

=back

=head1 FUNCTIONS

=head2 transmute_data

Usage:

 $data = transmute_data(%args)

Transmute data structure, die on failure. Input data is specified in the C<data>
argument, which will be modified in-place (so you'll need to clone it first if
you don't want to modify the original data). Rules is specified in C<rules>
argument.

Known arguments (C<*> means required):

=over

=item * data*

=item * rules

Array of rules. See L</RULES> for more details.

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

=item * rules_module

Specify name of module (without the C<Data::Transmute::Rules::> prefix) which
contains the actual rules. The module will be loaded and the rules retrieved
from its C<@RULES> package variable.

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

=back

=head2 reverse_rules

Usage:

 my $reverse_rules = reverse_rules(rules => [...]);

Create a reverse of rules, die on failure. For example, this set of rules:

 [
   [create_hash_key => {name=>'a', value=>1}],
   [rename_hash_key => {from=>'c', to=>'d'}],
 ]

when reversed will become:

 [
   [rename_hash_key => {from=>'d', to=>'c'}],
   [delete_hash_key => {name=>'a'}],
 ]

Some rules cannot be reversed, e.g. L</delete_hash_key> so when given rules that
contain that, the function will die. A rule can only be reversed for a subset of
arguments, e.g. L</rename_hash_key> with C<ignore> set to true or C<replace> set
to true cannot be reversed.

The reverse of a set of rules can be used to reverse back a transmuted data back
to the original.

Known arguments (C<*> means required):

=over

=item * rules

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

See L</transmute_data> for more details.

=item * rules_module

Either C<rules> or C<rules_module> is required. C<rules> takes precedence over
C<rules_module>.

See L</transmute_data> for more details.

=back

=head1 ENVIRONMENT

=head2 LOG_DATA_TRANSMUTE_STEP

Boolean. If set to true, will log each transmute step (rule by rule) at the
trace level using L<Log::ger>.

=head1 TODOS

Function to mass rename keys (by regex substitution, prefix, custom Perl code,
...). But this cannot produce reverse of rule.

Function to mass delete keys (by regex, prefix, ...). But this cannot produce
reverse of rule.

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

L<Bencher::Scenarios::DataTransmute>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
