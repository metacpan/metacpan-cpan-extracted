package App::ParseBounceMessage;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{parse_bounce_message} = {
    v => 1.1,
    summary => 'Parse a bounce email message and return a structure',
    args => {
        message_file => {
            summary => 'A file containing a single email message',
            schema => 'filename*',
            default => '-',
            description => <<'_',

Dash (`-`) means to get the message from standard input.

_
            pos => 0,
        },
    },
};
sub parse_bounce_message {
    require File::Slurper;
    require Mail::DeliveryStatus::BounceParser;

    my %args = @_;

    my $message = $args{message_file} eq '-' ?
        do { local $/; <STDIN> } :
        do { File::Slurper::read_text($args{message_file}) };

    my $bounce = Mail::DeliveryStatus::BounceParser->new($message);

    my @reports = $bounce->reports;
    [200, "OK", {
        addresses       => [$bounce->addresses],
        num_reports     => [scalar(@reports)],
        reports         => [
            map { +{
                reporting_mta   => $_->get('reporting_mta'),
                arrival_date    => $_->get('arrival-date'),
                final_recipient => $_->get('final-recipient'),
                action          => $_->get('action'),
                status          => $_->get('status'),
                diagnostic_code => $_->get('diagnostic-code'),

                email           => $_->get('email'),
                std_reason      => $_->get('std_reason'),
                reason          => $_->get('reason'),
                host            => $_->get('host'),
                smtp_code       => $_->get('smtp_code'),
            } } @reports,
        ],
        orig_message_id => $bounce->orig_message_id,
    }];
}

1;
# ABSTRACT: Parse a bounce email message and return a structure

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ParseBounceMessage - Parse a bounce email message and return a structure

=head1 VERSION

This document describes version 0.002 of App::ParseBounceMessage (from Perl distribution App-ParseBounceMessage), released on 2021-05-25.

=head1 DESCRIPTION

This distribution provides a simple CLI for
L<Mail::DeliveryStatus::BounceParser>.

=head1 FUNCTIONS


=head2 parse_bounce_message

Usage:

 parse_bounce_message(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse a bounce email message and return a structure.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<message_file> => I<filename> (default: "-")

A file containing a single email message.

Dash (C<->) means to get the message from standard input.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-ParseBounceMessage>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ParseBounceMessage>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ParseBounceMessage>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Mail::DeliveryStatus::BounceParser>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
