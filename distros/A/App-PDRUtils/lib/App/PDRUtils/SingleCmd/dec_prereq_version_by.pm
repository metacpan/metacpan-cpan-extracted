package App::PDRUtils::SingleCmd::dec_prereq_version_by;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.120'; # VERSION

use 5.010001;
use strict;
use warnings;

use App::PDRUtils::SingleCmd;

App::PDRUtils::SingleCmd::create_cmd_from_dist_ini_cmd(
    dist_ini_cmd => 'dec_prereq_version_by',
);

1;
# ABSTRACT: Decrease prereq version by a certain decrement

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::SingleCmd::dec_prereq_version_by - Decrease prereq version by a certain decrement

=head1 VERSION

This document describes version 0.120 of App::PDRUtils::SingleCmd::dec_prereq_version_by (from Perl distribution App-PDRUtils), released on 2018-04-03.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

Decrease prereq version by a certain decrement.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<by>* => I<str>

=item * B<module>* => I<str>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-PDRUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDRUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDRUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
