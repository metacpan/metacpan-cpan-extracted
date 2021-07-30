package Data::Sah::Util::Subschema;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-29'; # DATE
our $DIST = 'Data-Sah-Util-Subschema'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Sah::Normalize qw(normalize_schema);
use Data::Sah::Resolve   qw(resolve_schema);

use Exporter qw(import);
our @EXPORT_OK = qw(extract_subschemas);

my %clausemeta_cache; # key = TYPE.CLAUSE

sub extract_subschemas {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $sch = shift;
    my $seen = shift // {};

    $seen->{"$sch"}++ and return ();

    unless ($opts->{schema_is_normalized}) {
        $sch = normalize_schema($sch);
    }

    my $res = resolve_schema(
        {schema_is_normalized => 1},
        $sch);

    my $typeclass = "Data::Sah::Type::$res->{type}";
    (my $typeclass_pm = "$typeclass.pm") =~ s!::!/!g;
    require $typeclass_pm;

    # XXX handle def and/or resolve schema into builtin types. for now we only
    # have one clause set because we don't handle those.
    my @clsets = @{ $res->{'clsets_after_type.alt.merge.merged'} };

    my @res;
    for my $clset (@clsets) {
        for my $clname (keys %$clset) {
            next unless $clname =~ /\A[A-Za-z][A-Za-z0-9_]*\z/;
            my $cache_key = "$sch->[0].$clname";
            my $clmeta = $clausemeta_cache{$cache_key};
            unless ($clmeta) {
                my $meth = "clausemeta_$clname";
                $clmeta = $clausemeta_cache{$cache_key} =
                    $typeclass->${\("clausemeta_$clname")};
            }
            next unless $clmeta->{subschema};
            my $op = $clset->{"$clname.op"};
            my @clvalues;
            if (defined($op) && ($op eq 'or' || $op eq 'and')) {
                @clvalues = @{ $clset->{$clname} };
            } else {
                @clvalues = ( $clset->{$clname} );
            }
            for my $clvalue (@clvalues) {
                my @subsch = $clmeta->{subschema}->($clvalue);
                push @res, @subsch;
                push @res, map { extract_subschemas($opts, $_, $seen) } @subsch;
            }
        }
    }

    @res;
}

1;
# ABSTRACT: Extract subschemas from a schema

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Util::Subschema - Extract subschemas from a schema

=head1 VERSION

This document describes version 0.005 of Data::Sah::Util::Subschema (from Perl distribution Data-Sah-Util-Subschema), released on 2021-07-29.

=head1 SYNOPSIS

 use Data::Sah::Util::Subschema qw(extract_subschemas)

 my $subschemas = extract_subschemas([array => of=>"int*"]);
 # => ("int*")

 $subschemas = extract_subschemas([any => of=>["int*", [array => of=>"int"]]]);
 # => ("int*", [array => of=>"int"], "int")

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 extract_subschemas([ \%opts, ] $sch) => list

Extract all subschemas found inside Sah schema C<$sch>. Schema will be
normalized first, then schemas from all clauses which contains subschemas will
be collected recursively.

Known options:

=over

=item * schema_is_normalized => bool (default: 0)

When set to true, function will skip normalizing schema and assume input schema
is normalized.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Util-Subschema>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Util-Subschema>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Util-Subschema>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah>, L<Data::Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
