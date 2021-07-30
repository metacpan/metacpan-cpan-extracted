package Data::Sah::Resolve;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-29'; # DATE
our $DIST = 'Data-Sah-Resolve'; # DIST
our $VERSION = '0.011'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(resolve_schema);

sub _clset_has_merge {
    my $clset = shift;
    for (keys %$clset) {
        return 1 if /\Amerge\./;
    }
    0;
}

sub _resolve {
    my ($opts, $res) = @_;

    my $type = $res->{type};
    die "Cannot resolve Sah schema: circular schema definition: ".
        join(" -> ", @{$res->{resolve_path}}, $type)
        if grep { $type eq $_ } @{$res->{resolve_path}};

    unshift @{$res->{resolve_path}}, $type;

    # check whether $type is a built-in Sah type
    (my $typemod_pm = "Data/Sah/Type/$type.pm") =~ s!::!/!g;
    eval { require $typemod_pm; 1 };
    my $err = $@;
    unless ($err) {
        # already a builtin-type, so we stop here
        return;
    }
    die "Cannot resolve Sah schema: can't check whether $type is a builtin Sah type: $err"
        unless $err =~ /\ACan't locate/;

    # not a type, try a schema under Sah::Schema
    my $schmod = "Sah::Schema::$type";
    (my $schmod_pm = "$schmod.pm") =~ s!::!/!g;
    eval { require $schmod_pm; 1 };
    die "Cannot resolve Sah schema: not a known built-in Sah type '$type' (can't locate ".
        "Data::Sah::Type::$type) and not a known schema name '$type' ($@)"
            if $@;
    no strict 'refs';
    my $sch2 = ${"$schmod\::schema"};
    die "Cannot resolve Sah schema: BUG: Schema module $schmod doesn't contain \$schema"
        unless $sch2;
    $res->{type} = $sch2->[0];
    unshift @{ $res->{clsets_after_type} }, $sch2->[1];
    _resolve($opts, $res);
}

sub resolve_schema {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $sch = shift;

    # normalize
    unless ($opts->{schema_is_normalized}) {
        require Data::Sah::Normalize;
        $sch =  Data::Sah::Normalize::normalize_schema($sch);
    }

    my $res = {
        v => 2,
        type => $sch->[0],
        clsets_after_type => [$sch->[1]],
        resolve_path => [],
    };

    # resolve
    _resolve($opts, $res);

    # determine the "base restrictions" base
    my @clsets_have_merge;
    my $has_merge_prefixes; # whether any of the clsets have merge prefixes
    for (@{ $res->{clsets_after_type} }) {
        push @clsets_have_merge, _clset_has_merge($_);
        $has_merge_prefixes++ if $clsets_have_merge[-1];
    }
    # TODO: sanity check: the innermost base schema should not have merge prefixes
    my $idx = $#clsets_have_merge;
    while ($idx >= 0) {
        if ($opts->{allow_base_with_no_additional_clauses}) {
            last if !$clsets_have_merge[$idx];
        } else {
            last if keys(%{$res->{clsets_after_type}[$idx]}) > 0 && !$clsets_have_merge[$idx];
        }
        $idx--;
    }
    #use DD; dd $res->{clsets_after_type}; dd \@clsets_have_merge;
    $res->{base} = $res->{resolve_path}[$idx];
    $res->{clsets_after_base} = [grep {keys(%$_) > 0} @{ $res->{clsets_after_type} }[$idx .. $#clsets_have_merge]];

    # merge
    my @merged_clsets;
  MERGE: {
        unless ($has_merge_prefixes) {
            @merged_clsets = grep { keys(%$_)>0 } @{ $res->{clsets_after_type} };
            last;
        }
        @merged_clsets = ($res->{clsets_after_type}[0]);
        for my $i (1 .. $#clsets_have_merge) {
            my $clset = $res->{clsets_after_type}[$i];
            next unless keys(%$clset) > 0;
            if ($clsets_have_merge[$i]) {
                state $merger = do {
                    require Data::ModeMerge;
                    my $mm = Data::ModeMerge->new(config => {
                        recurse_array => 1,
                    });
                    $mm->modes->{NORMAL}  ->prefix   ('merge.normal.');
                    $mm->modes->{NORMAL}  ->prefix_re(qr/\Amerge\.normal\./);
                    $mm->modes->{ADD}     ->prefix   ('merge.add.');
                    $mm->modes->{ADD}     ->prefix_re(qr/\Amerge\.add\./);
                    $mm->modes->{CONCAT}  ->prefix   ('merge.concat.');
                    $mm->modes->{CONCAT}  ->prefix_re(qr/\Amerge\.concat\./);
                    $mm->modes->{SUBTRACT}->prefix   ('merge.subtract.');
                    $mm->modes->{SUBTRACT}->prefix_re(qr/\Amerge\.subtract\./);
                    $mm->modes->{DELETE}  ->prefix   ('merge.delete.');
                    $mm->modes->{DELETE}  ->prefix_re(qr/\Amerge\.delete\./);
                    $mm->modes->{KEEP}    ->prefix   ('merge.keep.');
                    $mm->modes->{KEEP}    ->prefix_re(qr/\Amerge\.keep\./);
                    $mm;
                };
                my $merge_res = $merger->merge($merged_clsets[-1], $clset);
                unless ($merge_res->{success}) {
                    die "Can't resolve schema: Can't merge clause set: $merge_res->{error}";
                }
                $merged_clsets[-1] = $merge_res->{result};
            } else {
                push @merged_clsets, $clset;
            }
        } # for clause set
    } # MERGE
    pop @merged_clsets if @merged_clsets && keys(%{$merged_clsets[-1]}) == 0;
    $res->{'clsets_after_type.alt.merge.merged'} = \@merged_clsets;

    $res;
}

1;
# ABSTRACT: Resolve Sah schema

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Resolve - Resolve Sah schema

=head1 VERSION

This document describes version 0.011 of Data::Sah::Resolve (from Perl distribution Data-Sah-Resolve), released on 2021-07-29.

=head1 SYNOPSIS

 use Data::Sah::Resolve qw(resolve_schema);

 my $sch = resolve_schema("int");
 # => {
 #      v => 2,
 #      type=>"int",
 #      clsets_after_type => [],
 #      "clsets_after_type.alt.merge.merged" => [],
 #      base=>"int",
 #      clsets_after_base => [],
 #      resolve_path => ["int"],
 #    }

 my $sch = resolve_schema("posint*");
 # => {
 #      v => 2,
 #      type=>"int",
 #      clsets_after_type => [{min=>1}, {req=>1}],
 #      "clsets_after_type.alt.merge.merged" => [{min=>1}, {req=>1}],
 #      base => "posint",
 #      clsets_after_base => [{req=>1}],
 #      resolve_path => ["int","posint"],
 #    }

 my $sch = resolve_schema([posint => div_by => 3]);
 # => {
 #      v => 2,
 #      type=>"int",
 #      clsets_after_type => [{min=>1}, {div_by=>3}],
 #      "clsets_after_type.alt.merge.merged" => [{min=>1}, {div_by=>3}],
 #      base => "posint",
 #      clsets_after_base => [{div_by=>3}],
 #      resolve_path => ["int","posint"],
 #    }
 # => ["int", {min=>1}, {div_by=>3}]

 my $sch = resolve_schema(["posint", "merge.delete.min"=>undef, div_by => 3]);
 # basically becomes: ["int", div_by=>3]
 # => {
 #      v => 2,
 #      type=>"int",
 #      clsets_after_type => [{min=>1}, {"merge.delete.min"=>undef, div_by=>3}],
 #      "clsets_after_type.alt.merge.merged" => [{div_by=>3}],
 #      base => undef,
 #      clsets_after_base => [{div_by=>3}],
 #      resolve_path => ["int","posint"],
 #    }
 # => ["int", {min=>1}, {div_by=>3}]

=head1 DESCRIPTION

This module provides L</resolve_schema>.

=head1 FUNCTIONS

=head2 resolve_schema

Usage:

 my $res = resolve_schema([ \%opts, ] $sch); # => hash

Sah schemas can be defined in terms of other schemas as base. The resolving
process follows the (outermost) base schema until it finds a builtin type as the
(innermost) base. It then returns a hash result (a L<DefHash> with C<v>=2)
containing the type as well other information like the collected clause sets and
others.

This routine performs the following steps:

=over

=item 1. Normalize the schema

Unless C<schema_is_normalized> option is true, in which case schema is assumed
to be normalized already.

=item 2. Check if the schema's type is a builtin type

Currently this is done by checking if the module of the name C<<
Data::Sah::Type::<type> >> is loadable. If it is a builtin type then we are
done.

=item 3. Check if the schema's type is the name of another schema

This is done by checking if C<< Sah::Schema::<name> >> module exists and is
loadable. If this is the case then we retrieve the base schema from the
C<$schema> variable in the C<< Sah::Schema::<name> >> package and repeat the
process while accumulating and/or merging the clause sets.

=item 4. If schema's type is neither, we die.

=back

Will also die on circularity or when there is other failures like failing to get
schema from the schema module.

Example 1: C<int>.

First we normalize to C<< ["int",{}] >>. The type is C<int> and it is a builtin
type (L<Data::Sah::Type::int> exists). The final result is:

 {
   v => 2,
   type=>"int",
   clsets_after_type => [],
   "clsets_after_type.alt.merge.unmerged" => [],
   base=>undef,
   clsets_after_base => [],
   resolve_path => ["int"],
 }

Example 2: C<posint*>.

First we normalize to C<< ["posint",{req=>1}] >>. The type part of this schema
is C<posint> and it is actually the name of another schema because
C<Data::Sah::Type::posint> is not found and we find schema module
L<Sah::Schema::posint>) instead. We then retrieve the C<posint> schema from the
schema module's C<$schema> and we get C<< ["int", {min=>1}] >> (additional
informative clauses omitted for brevity). We now try to resolve C<int> and find
that it's a builtin type. So the final result is:

 {
   v => 2,
   type=>"int",
   clsets_after_type => [{min=>1}, {req=>1}],
   "clsets_after_type.alt.merge.unmerged" => [{min=>1}, {req=>1}],
   base => "posint",
   clsets_after_base => [{req=>1}],
   resolve_path => ["int","posint"],
 }

Known options:

=over

=item * schema_is_normalized

Bool, default false. When set to true, function will skip normalizing schema and
assume input schema is normalized.

=item * allow_base_with_no_additional_clauses

Bool, default false. Normally, a schema like C<< "posint" >> or C<<
["posint",{}] >> will result in C<"int"> as the base (because the schema does
not add any additional clauses to the "posint" schema) while C<<
["posint",{div_by=>2}] >> will result in C<"posint"> as the base. But if this
setting is set to true, then all the previous examples will result in
C<"posint"> as the base.

=back

As mentioned, result is a hash conforming to the L<DefHash> restriction. The
following keys will be returned:

=over

=item * v

Integer, has the value of 2. A non-compatible change of result will bump this
version number.

=item * type

Str, the Sah builtin type name.

=item * clsets_after_type

All the collected clause sets, from the deepest base schema to the outermost,
and to the clause set of the original unresolved schema.

=item * clsets_after_type.alt.merge.merged

Like L</clsets_after_type>, but the clause sets are merged according to the
L<Sah> merging specification.

=item * base

Str. Might be undef. The outermost base schema (or type) that can be used as
"base restriction", meaning its restrictions (clause sets) must all be
fulfilled. After this base's clause sets, the next additional clause sets will
not contain any merge prefixes. Because if additional clause sets contained
merge prefixes, they could modify or remove restrictions set by the base instead
of just adding more restrictions (which is the whole point of merging).

=item * clsets_after_base

Clause sets after the "base restriction" base. This is additional restrictions
that are imposed to the restrictions of the base schema. They do not contain
merge prefixes.

=item * resolve_path

Array. This is a list of schema type names or builtin type names, from the
deepest to the shallowest. The first element of this arrayref is the builtin Sah
type and the last element is the original unresolved schema's type.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Resolve>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Resolve>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Resolve>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah>, L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
