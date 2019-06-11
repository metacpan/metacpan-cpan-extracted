package App::PowerManagementUtils;

our $DATE = '2019-06-09'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{prevent_sleep_while} = {
    v => 1.1,
    summary => 'Prevent sleep while running a command',
    description => <<'_',

Uses <pm:Proc::Govern>. For more options when running command, e.g. timeout,
load control, autorestart, use the module or its CLI <prog:govproc> instead.

_
    args => {
        command => {
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
};
sub prevent_sleep_while {
    require Proc::Govern;

    my %args = @_;

    my $exit = Proc::Govern::govern_process(
        command => $args{command},
        no_sleep => 1,
    );

    [200, "Exit code is $exit", "", {"cmdline.exit_code"=>$exit}];
}

1;
# ABSTRACT: CLI utilities related to power management

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PowerManagementUtils - CLI utilities related to power management

=head1 VERSION

This document describes version 0.002 of App::PowerManagementUtils (from Perl distribution App-PowerManagementUtils), released on 2019-06-09.

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to screensaver:

=over

=item * L<prevent-sleep>

=item * L<prevent-sleep-while>

=item * L<sleep-is-prevented>

=item * L<unprevent-sleep>

=back

=head1 FUNCTIONS


=head2 prevent_sleep_while

Usage:

 prevent_sleep_while(%args) -> [status, msg, payload, meta]

Prevent sleep while running a command.

Uses L<Proc::Govern>. For more options when running command, e.g. timeout,
load control, autorestart, use the module or its CLI L<govproc> instead.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<command>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PowerManagementUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PowerManagementUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PowerManagementUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
