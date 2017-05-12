package App::lcpan::Cmd::mentions_by_mod;

our $DATE = '2017-02-03'; # DATE
our $VERSION = '1.017'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

require App::lcpan;
require App::lcpan::Cmd::mentions;

our %SPEC;

my $mentions_args = $App::lcpan::Cmd::mentions::SPEC{handle_cmd}{args};

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List POD mentions by module(s)',
    description => <<'_',

This subcommand is a shortcut for:

    % lcpan mentions --mentioner-module MOD

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mods_args,
        (map {$_ => $mentions_args->{$_}}
             grep {!/\A(mentioner_.+)\z/}
             keys %$mentions_args),
    },
};
sub handle_cmd {
    my %args = @_;

    my %mentions_args = %args;

    delete $mentions_args{modules};
    $mentions_args{mentioner_modules} = $args{modules};

    App::lcpan::Cmd::mentions::handle_cmd(%mentions_args);
}

1;
# ABSTRACT: List POD mentions by module(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::mentions_by_mod - List POD mentions by module(s)

=head1 VERSION

This document describes version 1.017 of App::lcpan::Cmd::mentions_by_mod (from Perl distribution App-lcpan), released on 2017-02-03.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

List POD mentions by module(s).

This subcommand is a shortcut for:

 % lcpan mentions --mentioner-module MOD

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

=item * B<mentioned_authors> => I<array[str]>

Filter by author(s) of module/script being mentioned.

=item * B<mentioned_modules> => I<array[str]>

Filter by module name(s) being mentioned.

=item * B<mentioned_scripts> => I<array[str]>

Filter by script name(s) being mentioned.

=item * B<modules>* => I<array[perl::modname]>

=item * B<type> => I<str> (default: "any")

Filter by type of things being mentioned.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
