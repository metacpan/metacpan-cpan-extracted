package Data::Sah::Filter::perl::Str::replace_underscores_with_dashes;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-28'; # DATE
our $DIST = 'Data-Sah-Filter-perl-Str-replace_underscores_with_dashes'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

sub meta {
    +{
        v => 1,
        summary => 'Replace underscores in string with dashes',
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; \$tmp =~ s/_/-/g; \$tmp }",
    );

    $res;
}

1;
# ABSTRACT: Replace underscores in string with dashes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::replace_underscores_with_dashes - Replace underscores in string with dashes

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::Str::replace_underscores_with_dashes (from Perl distribution Data-Sah-Filter-perl-Str-replace_underscores_with_dashes), released on 2020-02-28.

=head1 SYNOPSIS

Use in Sah schema's C<prefilters> (or C<postfilters>) clause:

 ["str","prefilters",["Str::replace_underscores_with_dashes"]]

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter-perl-Str-replace_underscores_with_dashes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter-perl-Str-replace_underscores_with_dashes>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter-perl-Str-replace_underscores_with_dashes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Filter::perl::Str::replace_dashes_with_underscores>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
