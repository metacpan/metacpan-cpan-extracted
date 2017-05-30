package App::DumpOperaHistory;

our $DATE = '2017-05-30'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{dump_opera_history} = {
    v => 1.1,
    summary => 'Dump Opera history',
    description => <<'_',

This script supports Opera 12.x, the last "true" version of Opera. History is
stored in a plaintext file.

_
    args => {
        path => {
            schema => 'filename*',
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub dump_opera_history {
    my %args = @_;

    my $path = $args{path} // "$ENV{HOME}/.opera/global_history.dat";
    return [412, "Can't find $path"] unless -f $path;
    open my $fh, "<", $path or return [500, "Can't open $path: $!"];

    my @rows;
    my $resmeta = {};
    while (1) {
        my $row = {};
        defined($row->{title}           = <$fh>) or last; chomp $row->{title};
        defined($row->{url}             = <$fh>) or last; chomp $row->{url};
        defined($row->{last_visit_time} = <$fh>) or last; chomp $row->{last_visit_time};
        defined(my $flags               = <$fh>) or last; chomp($flags);

        if ($args{detail}) {
            push @rows, $row;
        } else {
            push @rows, $row->{url};
        }
    }

    $resmeta->{'table.fields'} = [qw/url title last_visit_time/]
        if $args{detail};
    [200, "OK", \@rows, $resmeta];
}

1;
# ABSTRACT: Dump Opera history

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DumpOperaHistory - Dump Opera history

=head1 VERSION

This document describes version 0.001 of App::DumpOperaHistory (from Perl distribution App-DumpOperaHistory), released on 2017-05-30.

=head1 SYNOPSIS

See the included script L<dump-opera-history>.

=head1 FUNCTIONS


=head2 dump_opera_history

Usage:

 dump_opera_history(%args) -> [status, msg, result, meta]

Dump Opera history.

This script supports Opera 12.x, the last "true" version of Opera. History is
stored in a plaintext file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<path> => I<filename>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DumpOperaHistory>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DumpOperaHistory>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DumpOperaHistory>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::DumpChromeHistory>

L<App::DumpHistoryHistory>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
