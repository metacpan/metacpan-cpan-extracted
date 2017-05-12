package App::ParseServices;

our $DATE = '2016-10-26'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{parse_services} = {
    v => 1.1,
    summary => 'Parse /etc/services',
    args => {
        filename => {
            schema => 'filename*',
            cmdline_aliases => {f=>{}},
        },
    },
};
sub parse_services {
    my %args = @_;

    my %ps_args;
    if (defined(my $fn = $args{filename})) {
        my $content;
        local $/;
        if ($fn eq '-') {
            $content = <STDIN>;
        } else {
            open my $fh, "<", $fn or return [500, "Can't open $fn: $!"];
            $content = <$fh>;
        }
        $ps_args{content} = $content;
    }
    require Parse::Services;
    Parse::Services::parse_services(%ps_args);
}

1;
# ABSTRACT: Parse /etc/hosts (CLI)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ParseServices - Parse /etc/hosts (CLI)

=head1 VERSION

This document describes version 0.001 of App::ParseServices (from Perl distribution App-ParseServices), released on 2016-10-26.

=head1 FUNCTIONS


=head2 parse_services(%args) -> [status, msg, result, meta]

Parse /etc/services.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<filename>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ParseServices>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ParseServices>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ParseServices>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Parse::Hosts>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
