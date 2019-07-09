package CPAN::Changes::Cwalitee;

our $DATE = '2019-07-08'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Cwalitee::Common;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       calc_cpan_changes_cwalitee
                       list_cpan_changes_cwalitee_indicators
               );

our %SPEC;

$SPEC{list_cpan_changes_cwalitee_indicators} = {
    v => 1.1,
    args => {
        Cwalitee::Common::args_list('CPAN::Changes::'),
    },
};
sub list_cpan_changes_cwalitee_indicators {
    my %args = @_;

    Cwalitee::Common::list_cwalitee_indicators(
        prefix => 'CPAN::Changes::',
        %args,
    );
}

$SPEC{calc_cpan_changes_cwalitee} = {
    v => 1.1,
    args => {
        Cwalitee::Common::args_calc('CPAN::Changes::'),
        path => {
            schema => 'pathname*',
            req => 1,
        },
    },
};
sub calc_cpan_changes_cwalitee {
    require File::Slurper;

    my %fargs = @_;
    my $path = delete $fargs{path};

    my $parse_attempted;
    Cwalitee::Common::calc_cwalitee(
        prefix => 'CPAN::Changes::',
        %fargs,
        code_init_r => sub {
            return {
                path => $path,
                file_content => File::Slurper::read_text($path),
            };
        },
        code_fixup_r => sub {
            my %cargs = @_;
            my $ind = $cargs{indicator};
            my $r   = $cargs{r};

            if ($ind->{priority} > 1 && !$parse_attempted++) {
                require CPAN::Changes::Subclass::Cwalitee;
                eval {
                    $r->{parsed} = CPAN::Changes::Subclass::Cwalitee->load_string(
                        $r->{file_content});
                };
            }
        },
    );
}

1;
# ABSTRACT: Calculate the cwalitee of your CPAN Changes file

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Changes::Cwalitee - Calculate the cwalitee of your CPAN Changes file

=head1 VERSION

This document describes version 0.004 of CPAN::Changes::Cwalitee (from Perl distribution CPAN-Changes-Cwalitee), released on 2019-07-08.

=head1 SYNOPSIS

 use CPAN::Changes::Cwalitee qw(
     calc_cpan_changes_cwalitee
     list_cpan_changes_cwalitee_indicators
 );

 my $res = calc_cpan_changes_cwalitee(
     path => 'Changes',
 );

=head1 DESCRIPTION

B<What is CPAN Changes cwalitee?> A metric to attempt to gauge the quality of
your CPAN Changes file. Since actual quality is hard to measure, this metric is
called a "cwalitee" instead. The cwalitee concept follows "kwalitee" [1] which
is specifically to measure the quality of CPAN distribution. I pick a different
spelling to avoid confusion with kwalitee. And unlike kwalitee, the unqualified
term "cwalitee" does not refer to a specific, particular subject. There can be
"CPAN Changes cwalitee" (which is handled by this module), "module abstract
cwalitee", and so on.

=head1 INTERNAL NOTES

B<Indicator priority.> At priority 10, Changes file is parsed using
CPAN::Changes and the result # it put in 'parsed' key.

=head1 FUNCTIONS


=head2 calc_cpan_changes_cwalitee

Usage:

 calc_cpan_changes_cwalitee(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_indicator> => I<array[str]>

Do not use these indicators.

=item * B<exclude_indicator_module> => I<array[perl::modname]>

Do not use indicators from these modules.

=item * B<exclude_indicator_status> => I<array[str]>

Do not use indicators having these statuses.

=item * B<include_indicator> => I<array[str]>

Only use these indicators.

=item * B<include_indicator_module> => I<array[perl::modname]>

Only use indicators from these modules.

=item * B<include_indicator_status> => I<array[str]> (default: ["stable"])

Only use indicators having these statuses.

=item * B<min_indicator_severity> => I<uint> (default: 1)

Minimum indicator severity.

=item * B<path>* => I<pathname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_cpan_changes_cwalitee_indicators

Usage:

 list_cpan_changes_cwalitee_indicators(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<exclude> => I<array[str]>

Exclude by name.

=item * B<exclude_module> => I<array[perl::modname]>

Exclude by module.

=item * B<exclude_status> => I<array[str]>

Exclude by status.

=item * B<include> => I<array[str]>

Include by name.

=item * B<include_module> => I<array[perl::modname]>

Include by module.

=item * B<include_status> => I<array[str]> (default: ["stable"])

Include by status.

=item * B<max_severity> => I<int> (default: 5)

Maximum severity.

=item * B<min_severity> => I<int> (default: 1)

Minimum severity.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Changes-Cwalitee>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Changes-Cwalitee>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Changes-Cwalitee>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

[1] L<https://cpants.cpanauthors.org/>

L<App::CPANChangesCwaliteeUtils> for the CLI's.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
