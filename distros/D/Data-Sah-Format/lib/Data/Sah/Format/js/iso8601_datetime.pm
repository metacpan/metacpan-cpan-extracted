package Data::Sah::Format::js::iso8601_datetime;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

sub format {
    my %args = @_;

    my $dt    = $args{data_term};
    my $fargs = $args{args} // {};

    my $attempt_parse = $fargs->{attempt_parse} // 1;

    my $res = {};

    $res->{expr} = join(
        "",
        "$dt instanceof Date ? (isNaN($dt) ? d : $dt.toISOString().substring(0, 19) + 'Z') : ",
        $attempt_parse ? "(function(pd) { pd = new Date($dt); return isNaN(pd) ? $dt : pd.toISOString().substring(0, 19) + 'Z' })()" : "$dt",
    );

    $res;
}

1;
# ABSTRACT: Format date as ISO8601 datetime (e.g. 2016-06-13T03:08:00Z)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Format::js::iso8601_datetime - Format date as ISO8601 datetime (e.g. 2016-06-13T03:08:00Z)

=head1 VERSION

This document describes version 0.003 of Data::Sah::Format::js::iso8601_datetime (from Perl distribution Data-Sah-Format), released on 2017-07-10.

=head1 DESCRIPTION

=for Pod::Coverage ^(format)$

=head1 FORMATTER ARGUMENTS

=head2 attempt_parse => bool (default: 1)

If this argument is set to true (which is the default), then non-Date instance
value (e.g. numbers, strings) will be attempted to be converted to Date
instances first then formatted if possible.

If this argument is set to false, then non-Date instance values will be passed
unformatted.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Format>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
