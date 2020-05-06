package App::lcpan::Cmd::ver_cmp_installed;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-06'; # DATE
our $DIST = 'App-lcpan-CmdBundle-ver'; # DIST
our $VERSION = '0.050'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use ExtUtils::MakeMaker;
use Function::Fallback::CoreOrPP qw(clone);

require App::lcpan;
require App::lcpan::Cmd::ver_cmp_list;

our %SPEC;

$SPEC{handle_cmd} = do {
    my $meta = clone($App::lcpan::Cmd::ver_cmp_list::SPEC{handle_cmd});
    $meta->{summary} = 'Compare installed module versions against database';
    delete $meta->{args}{list};
    $meta->{args} = {
        %{ $meta->{args} },
        %App::lcpan::finclude_core_args,
        %App::lcpan::finclude_noncore_args,
    };
    $meta;
};
sub handle_cmd {
    require Module::CoreList::More;
    require PERLANCAR::Module::List;

    my %args = @_;
    my $include_core    = $args{include_core} // 1;
    my $include_noncore = $args{include_noncore} // 1;

    my $mod_paths = PERLANCAR::Module::List::list_modules(
        "", {list_modules=>1, recurse=>1, return_path=>1},
    );

    my @list;
    for my $mod (sort keys %$mod_paths) {
        my $ver = MM->parse_version($mod_paths->{$mod});
        $ver = 0 if defined($ver) && $ver eq 'undef';
        eval { $ver = version->parse($ver)->numify };
        if ($@) { warn; $ver = 0 }

        my $is_core = Module::CoreList::More->is_still_core(
            $mod, undef, $ver);
        next if !$include_core    &&  $is_core;
        next if !$include_noncore && !$is_core;
        push @list, "$mod\t$ver\n";
    }

    App::lcpan::Cmd::ver_cmp_list::handle_cmd(%args, list=>join("", @list));
}

1;
# ABSTRACT: Compare installed module versions against database

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::ver_cmp_installed - Compare installed module versions against database

=head1 VERSION

This document describes version 0.050 of App::lcpan::Cmd::ver_cmp_installed (from Perl distribution App-lcpan-CmdBundle-ver), released on 2020-05-06.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<ver-cmp-installed>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Compare installed module versions against database.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<show> => I<str> (default: "older-than-db")

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-ver>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-ver>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-ver>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::cpanoutdated>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
