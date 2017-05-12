package Data::Sah::Format::perl::iso8601_datetime;

our $DATE = '2016-06-17'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

sub format {
    my %args = @_;

    my $dt    = $args{data_term};
    my $fargs = $args{args} // {};

    my $format_datetime   = $fargs->{format_datetime} // 1;
    my $format_timemoment = $fargs->{format_timemoment} // 1;

    my $res = {};

    $res->{expr} = join(
        "",
        "$dt =~ /\\A\\d+(\\.\\d+)?\\z/ ? do { my \@t = gmtime($dt); sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ', \$t[5]+1900, \$t[4]+1, \$t[3], \$t[2], \$t[1], \$t[0]) } : ",
        ($format_datetime ?
             # convert to UTC first
             "ref($dt) eq 'DateTime' ? DateTime->from_epoch(epoch => $dt\->epoch)->iso8601 . 'Z' : " : ""),
        ($format_timemoment ?
             "ref($dt) eq 'Time::Moment' ? $dt\->at_utc->strftime('%Y-%m-%dT%H:%M:%SZ') : " : ""),
        $dt,
    );

    $res;
}

1;
# ABSTRACT: Format date as ISO8601 datetime (e.g. 2016-06-13T03:08:00Z)

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Format::perl::iso8601_datetime - Format date as ISO8601 datetime (e.g. 2016-06-13T03:08:00Z)

=head1 VERSION

This document describes version 0.002 of Data::Sah::Format::perl::iso8601_datetime (from Perl distribution Data-Sah-Format), released on 2016-06-17.

=head1 DESCRIPTION

Will format epoch as ISO8601 datetime. By default will also format L<DateTime>
and L<Time::Moment> instances, but this can be turned off. Will leave other kind
of data unformatted.

=for Pod::Coverage ^(format)$

=head1 FORMATTER ARGUMENTS

=head2 format_datetime => bool (default: 1)

=head2 format_timemoment => bool (default: 1)

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

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
