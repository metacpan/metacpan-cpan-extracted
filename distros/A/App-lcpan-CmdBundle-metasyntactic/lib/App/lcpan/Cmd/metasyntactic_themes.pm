package App::lcpan::Cmd::metasyntactic_themes;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List all Acme::MetaSyntactic theme modules',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::detail_args,
        %App::lcpan::fauthor_args,
    },
};
sub handle_cmd {
    my %args = @_;
    my $res = App::lcpan::modules(%args, namespaces => ['Acme::MetaSyntactic']);
    return $res unless $res->[0] == 200;
    my @fres;
    for my $item (@{ $res->[2] }) {
        my $mod = $args{detail} ? $item->{module} : $item;
        next unless $mod =~ /^Acme::MetaSyntactic::[a-z0-9]/;
        if ($args{detail}) {
            ($item->{theme} = $mod) =~ s/^Acme::MetaSyntactic:://;
        } else {
            $item =~ s/^Acme::MetaSyntactic:://;
        }
        push @fres, $item;
    }
    $res->[2] = \@fres;
    unshift @{ $res->[3]{'table.fields'} }, 'theme';
    $res;
}

1;
# ABSTRACT: List all Acme::MetaSyntactic theme modules

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::metasyntactic_themes - List all Acme::MetaSyntactic theme modules

=head1 VERSION

This document describes version 0.003 of App::lcpan::Cmd::metasyntactic_themes (from Perl distribution App-lcpan-CmdBundle-metasyntactic), released on 2017-07-10.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<metasyntactic-themes>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, result, meta]

List all Acme::MetaSyntactic theme modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-metasyntactic>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-metasyntactic>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-metasyntactic>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
