package Data::Sah::Filter::perl::Str::try_decode_json;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Data-Sah-Filter-perl-Str-try_decode_json'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'JSON-decode if we can, otherwise leave string as-is',
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{modules}{"JSON::PP"} //= 0;
    $res->{expr_filter} = join(
        "",
        "do { my \$decoded; eval { \$decoded = JSON::PP->new->allow_nonref->decode($dt); 1 }; \$@ ? $dt : \$decoded }",
    );

    $res;
}

1;
# ABSTRACT: JSON-decode if we can, otherwise leave string as-is

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::try_decode_json - JSON-decode if we can, otherwise leave string as-is

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::Str::try_decode_json (from Perl distribution Data-Sah-Filter-perl-Str-try_decode_json), released on 2020-02-11.

=head1 SYNOPSIS

Use in Sah schema's C<prefilters> (or C<postfilters>) clause:

 ["str","prefilters",["Str::try_decode_json"]]

=head1 DESCRIPTION

This rule is sometimes convenient if you want to accept unquoted string or a
data structure (encoded in JSON). This means, compared to just decoding from
JSON, you don't have to always quote your string. But beware of traps like the
bare values C<null>, C<true>, C<false> becoming undef/1/0 in Perl instead of
string literals, because they can be JSON-decoded.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter-perl-Str-try_decode_json>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter-perl-Str-try_decode_json>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter-perl-Str-try_decode_json>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
