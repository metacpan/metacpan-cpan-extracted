package App::MacVictimUtils;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{delete_ds_store} = {
    v => 1.1,
    summary => 'Recursively delete .DS_Store files',
    args => {
        dirs => {
            schema => ['array*', of=>'dirname*'],
            pos => 0,
            greedy => 1,
        },
    },
    features => {
        dry_run => 1,
    },
};
sub delete_ds_store {
    require File::Find;

    my %args = @_;

    my @dirs = @{ $args{dirs} || ["."] };

    File::Find::find(
        sub {
            return unless -f && $_ eq '.DS_Store';
            if ($args{-dry_run}) {
                log_info("[DRY] Deleting %s/.DS_Store ...", $File::Find::dir);
                return;
            }
            log_info("Deleting %s/.DS_Store ...", $File::Find::dir);
            unlink $_ or do {
                log_warn("Can't delete %s/.DS_Store: %s", $File::Find::dir, $!);
            };
        },
        @dirs,
    );
    [200];
}

1;
# ABSTRACT: CLI utilities for when dealing with Mac computers/files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MacVictimUtils - CLI utilities for when dealing with Mac computers/files

=head1 VERSION

This document describes version 0.002 of App::MacVictimUtils (from Perl distribution App-MacVictimUtils), released on 2021-05-25.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<delete-ds-store>

=back

=head1 FUNCTIONS


=head2 delete_ds_store

Usage:

 delete_ds_store(%args) -> [$status_code, $reason, $payload, \%result_meta]

Recursively delete .DS_Store files.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<dirs> => I<array[dirname]>


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-MacVictimUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MacVictimUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MacVictimUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
