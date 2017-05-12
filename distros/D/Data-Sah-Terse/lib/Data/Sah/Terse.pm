package Data::Sah::Terse;

our $DATE = '2015-01-03'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Sah::Normalize qw(normalize_schema);

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(terse_schema);

# get type, this is a duplicate Data::Sah::Util::Type's get_type(). we can use
# it but that will currently pull Data-Sah as dependency.
sub _get_type {
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

sub _get_cset {
    my ($sch, $opts) = @_;

    if (ref($sch) eq 'ARRAY') {
        my $schn = $opts->{schema_is_normalized} ? $sch :
            normalize_schema($sch);
        return $schn->[1];
    } else {
        if ($sch =~ /\*/) {
            return {req=>1};
        } else {
            return {};
        }
    }
}

sub terse_schema {
    my ($sch, $opts) = @_;
    my $type = _get_type($sch);
    if ($type eq 'array') {
        my $cset = _get_cset($sch);
        return $type unless $cset->{of};
        return $type . "[" . terse_schema($cset->{of}) . "]";
    } elsif ($type eq 'any' || $type eq 'all') {
        my $cset = _get_cset($sch);
        return $type unless $cset->{of} && @{ $cset->{of} };
        my $join = $type eq 'any' ? '|' : ' & ';
        return join($join, map {terse_schema($_)} @{ $cset->{of} });
    } else {
        return $type;
    }
}

1;
# ABSTRACT: Make human-readable terse representation of Sah schema

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Terse - Make human-readable terse representation of Sah schema

=head1 VERSION

This document describes version 0.02 of Data::Sah::Terse (from Perl distribution Data-Sah-Terse), released on 2015-01-03.

=head1 SYNOPSIS

 use Data::Sah::Terse qw(terse_schema);

 say terse_schema("int");                                      # int
 say terse_schema(["int*", min=>0, max=>10]);                  # int
 say terse_schema(["array", {of=>"int"}]);                     # array[int]
 say terse_schema(["any*", of=>['int',['array'=>of=>"int"]]]); # int|array[int]

=head1 DESCRIPTION

=head1 FUNCTIONS

None exported by default, but they are exportable.

=head2 terse_schema($sch[, \%opts]) => str

Make a human-readable terse representation of Sah schema. Currently only schema
type is shown, all clauses are ignored. Special handling for types C<array>,
C<any> and C<all>. This routine is suitable for showing type in a function or
CLI help message.

Options:

=over

=item * schema_is_normalized => bool

=back

=head1 SEE ALSO

L<Data::Sah::Compiler::human>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Terse>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Terse>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Terse>

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
