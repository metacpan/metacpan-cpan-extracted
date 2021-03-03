package Data::Sah::Resolve;

our $DATE = '2021-02-27'; # DATE
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(resolve_schema);

sub _resolve {
    my ($opts, $type, $clsets, $seen) = @_;

    die "Recursive schema definition: ".join(" -> ", @$seen, $type)
        if grep { $type eq $_ } @$seen;
    push @$seen, $type;

    (my $typemod_pm = "Data/Sah/Type/$type.pm") =~ s!::!/!g;
    eval { require $typemod_pm; 1 };
    my $err = $@;
    # already a builtin-type, so just return the schema's type name & clause set
    return [$type, $clsets] unless $err;
    die "Can't check whether $type is a builtin Sah type: $err"
        unless $err =~ /\ACan't locate/;

    # not a type, try a schema under Sah::Schema
    my $schmod = "Sah::Schema::$type";
    (my $schmod_pm = "$schmod.pm") =~ s!::!/!g;
    eval { require $schmod_pm; 1 };
    die "Not a known built-in Sah type '$type' (can't locate ".
        "Data::Sah::Type::$type) and not a known schema name '$type' ($@)"
            if $@;
    no strict 'refs';
    my $sch2 = ${"$schmod\::schema"};
    die "BUG: Schema module $schmod doesn't contain \$schema" unless $sch2;
    unshift @$clsets, $sch2->[1];
    _resolve($opts, $sch2->[0], $clsets, $seen);
}

sub resolve_schema {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $sch = shift;

    unless ($opts->{schema_is_normalized}) {
        require Data::Sah::Normalize;
        $sch =  Data::Sah::Normalize::normalize_schema($sch);
    }
    $opts->{merge_clause_sets} //= 1;

    my $seen = [];
    my $res = _resolve($opts, $sch->[0], keys(%{$sch->[1]}) ? [$sch->[1]] : [], $seen);

  MERGE:
    {
        last unless $opts->{merge_clause_sets};
        last if @{ $res->[1] } < 2;

        my @clsets = (shift @{ $res->[1] });
        for my $clset (@{ $res->[1] }) {
            my $has_merge_mode_keys;
            for (keys %$clset) {
                if (/\Amerge\./) {
                    $has_merge_mode_keys = 1;
                    last;
                }
            }
            if ($has_merge_mode_keys) {
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
                my $merge_res = $merger->merge($clsets[-1], $clset);
                unless ($merge_res->{success}) {
                    die "Can't merge clause set: $merge_res->{error}";
                }
                $clsets[-1] = $merge_res->{result};
            } else {
                push @clsets, $clset;
            }
        }

        $res->[1] = \@clsets;
    }

    $res->[2] = $seen if $opts->{return_intermediates};

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

This document describes version 0.008 of Data::Sah::Resolve (from Perl distribution Data-Sah-Resolve), released on 2021-02-27.

=head1 SYNOPSIS

 use Data::Sah::Resolve qw(resolve_schema);

 my $sch = resolve_schema("int");
 # => ["int", []]

 my $sch = resolve_schema("posint*");
 # => ["int", [{min=>1}, {req=>1}]

 my $sch = resolve_schema([posint => div_by => 3]);
 # => ["int", {min=>1}, {div_by=>3}]

 my $sch = resolve_schema(["posint", "merge.delete.min"=>undef, div_by => 3]);
 # => ["int", {div_by=>3}]

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 resolve_schema([ \%opts, ] $sch) => sch

Sah schemas can be defined in terms of other schemas. The resolving process
follows the base schema recursively until it finds a builtin type as the base.

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

Returns C<< [base_type, clause_sets] >>. If C<return_intermediates> option is
true, then the third elements will be the list of intermediate schema names.

Example 1: C<int>.

First we normalize to C<< ["int",{},{}] >>. The type is C<int> and it is a
builtin type (L<Data::Sah::Type::int> exists) so the final result is C<< ["int",
[]] >>.

Example 2: C<posint*>.

First we normalize to C<< ["posint",{req=>1},{}] >>. The type is C<posint> and
it is the name of another schema (L<Sah::Schema::posint>). We retrieve the
schema which is C<< ["int", {summary=>"Positive integer (1,2,3,...)", min=>1},
{}] >>. We now try to resolve C<int> and find that it's a builtin type. So the
final result is: C<< ["int", [ {req=>1}, {summary=>"Positive integer
(1,2,3,...)", min=>1} ]] >>.

Known options:

=over

=item * schema_is_normalized => bool (default: 0)

When set to true, function will skip normalizing schema and assume input schema
is normalized.

=item * merge_clause_sets => bool (default: 1)

=item * return_intermediates => bool

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
