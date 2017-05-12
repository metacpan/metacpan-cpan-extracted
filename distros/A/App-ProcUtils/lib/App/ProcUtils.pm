package App::ProcUtils;

our $DATE = '2016-01-18'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{list_parents} = {
    v => 1.1,
    summary => 'List all the parents of the current process',
};
sub list_parents {
    require Proc::Find::Parents;
    [200, "OK", Proc::Find::Parents::get_parent_processes()];
}

1;
# ABSTRACT: Command line utilities related to processes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ProcUtils - Command line utilities related to processes

=head1 VERSION

This document describes version 0.02 of App::ProcUtils (from Perl distribution App-ProcUtils), released on 2016-01-18.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<proc-list-parents>

=back

=head1 FUNCTIONS


=head2 list_parents() -> [status, msg, result, meta]

List all the parents of the current process.

This function is not exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ProcUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ProcUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ProcUtils>

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
