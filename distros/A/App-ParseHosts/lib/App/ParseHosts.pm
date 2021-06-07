package App::ParseHosts;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{parse_hosts} = {
    v => 1.1,
    summary => 'Parse /etc/hosts',
    args => {
        filename => {
            schema => 'filename*',
            cmdline_aliases => {f=>{}},
        },
    },
};
sub parse_hosts {
    my %args = @_;

    my %ph_args;
    if (defined(my $fn = $args{filename})) {
        my $content;
        local $/;
        if ($fn eq '-') {
            $content = <STDIN>;
        } else {
            open my $fh, "<", $fn or return [500, "Can't open $fn: $!"];
            $content = <$fh>;
        }
        $ph_args{content} = $content;
    }
    require Parse::Hosts;
    Parse::Hosts::parse_hosts(%ph_args);
}

1;
# ABSTRACT: Parse /etc/hosts (CLI)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ParseHosts - Parse /etc/hosts (CLI)

=head1 VERSION

This document describes version 0.003 of App::ParseHosts (from Perl distribution App-ParseHosts), released on 2021-05-25.

=head1 FUNCTIONS


=head2 parse_hosts

Usage:

 parse_hosts(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse E<sol>etcE<sol>hosts.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<filename>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or "OK" if status is
200. Third element ($payload) is optional, the actual result. Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ParseHosts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ParseHosts>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ParseHosts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Parse::Hosts>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
