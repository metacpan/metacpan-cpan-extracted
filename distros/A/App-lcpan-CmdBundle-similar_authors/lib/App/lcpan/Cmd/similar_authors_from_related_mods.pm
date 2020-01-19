package App::lcpan::Cmd::similar_authors_from_related_mods;

our $DATE = '2019-11-21'; # DATE
our $DIST = 'App-lcpan-CmdBundle-similar_authors'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::lcpan ();
use App::lcpan::Cmd::related_mods ();
use Hash::Subset 'hash_subset';

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List authors similar to the specified one, '.
        'by looking at how related their modules are',
    description => <<'_',

There are several ways one can regard an author as similar to another. This
subcommand offers one such way: by looking at how much their modules are related
to one another. Related modules are defined as modules that tend to be mentioned
together in POD documentation.

Experimental.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::author_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $author = $args{author};
    my $author_rec = $dbh->selectrow_hashref("SELECT * FROM author WHERE cpanid=?", {}, $author)
        or return [404, "No such author: $author"];

    my $modules;
    {
        my $sth = $dbh->prepare("SELECT name FROM module WHERE cpanid=?");
        $sth->execute($author);
        while (my $row = $sth->fetchrow_hashref) {
            push @$modules, $row->{name};
        }
    }
    @$modules or return [412, "Author '$author' does not have any modules"];

    my $related_mod_res = App::lcpan::Cmd::related_mods::handle_cmd(
        hash_subset(\%args, ['author']),
        modules => $modules,
        limit   => 100,
        with_scores => 1,
    );

    return $related_mod_res unless $related_mod_res->[0] == 200;

    my %similar_authors;
    for my $related_mod_entry (@{ $related_mod_res->[2] }) {
        $similar_authors{ $related_mod_entry->{author} }{score} +=
            $related_mod_entry->{score};
        push @{ $similar_authors{ $related_mod_entry->{author} }{modules} },
            $related_mod_entry->{module};
    }

    my @rows;
    for my $cpanid (sort { $similar_authors{$b}{score} <=> $similar_authors{$a}{score} } keys %similar_authors) {
        my $similar_author_entry = $similar_authors{$cpanid};
        push @rows, {
            author => $cpanid,
            score  => $similar_author_entry->{score},
            related_modules => join(", ", @{ $similar_author_entry->{modules} }),
        };
    }

    [200, "OK", \@rows, {'table.fields'=>[qw/author score related_modules/]}];
}

1;
# ABSTRACT: List authors similar to the specified one, by looking at how related their modules are

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::similar_authors_from_related_mods - List authors similar to the specified one, by looking at how related their modules are

=head1 VERSION

This document describes version 0.002 of App::lcpan::Cmd::similar_authors_from_related_mods (from Perl distribution App-lcpan-CmdBundle-similar_authors), released on 2019-11-21.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<similar-authors-from-related-mods>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List authors similar to the specified one, by looking at how related their modules are.

There are several ways one can regard an author as similar to another. This
subcommand offers one such way: by looking at how much their modules are related
to one another. Related modules are defined as modules that tend to be mentioned
together in POD documentation.

Experimental.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author>* => I<str>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-similar_authors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-similar_authors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-similar_authors>

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
