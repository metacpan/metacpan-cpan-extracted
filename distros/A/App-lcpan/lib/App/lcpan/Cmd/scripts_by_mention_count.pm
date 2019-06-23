package App::lcpan::Cmd::scripts_by_mention_count;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '1.034'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List scripts ranked by number of mentions',
    description => <<'_',

This shows the list of most mentioned scripts, that is, scripts who are
linked/referred to the most in PODs.

By default, each source module/script that mentions a script is counted as one
mention (`--count-per content`). Use `--count-per dist` to only count mentions
by modules/scripts from the same dist as one mention (so a script only gets a
maximum of 1 vote per dist). Use `--count-per author` to only count mentions by
modules/scripts from the same author as one mention (so a script only gets a
maximum of 1 vote per mentioning author).

By default, only mentions from other authors are included. Use
`--include-self-mentions` to also include mentions from the same author.

_
    args => {
        %App::lcpan::common_args,
        include_self_mentions => {
            schema => 'bool',
            default => 0,
        },
        count_per => {
            schema => ['str*', in=>['content', 'dist', 'author']],
            default => 'content',
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $count_per = $args{count_per} // 'content';

    my @where = ("mention.script_name IS NOT NULL");

    push @where, "targetfile.cpanid <> srcfile.cpanid"
        unless $args{include_self_mentions};

    my $count = '*';
    if ($count_per eq 'dist') {
        $count = 'DISTINCT srcfile.id';
    } elsif ($count_per eq 'author') {
        $count = 'DISTINCT srcfile.cpanid';
    }

    my $sql = "SELECT
  script.name script,
  COUNT($count) AS mention_count
FROM mention
LEFT JOIN file srcfile ON mention.source_file_id=srcfile.id
LEFT JOIN script ON mention.script_name=script.name
LEFT JOIN file targetfile ON script.file_id=targetfile.id
WHERE ".join(" AND ", @where)."
GROUP BY script.name
ORDER BY mention_count DESC
";

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/script mention_count/];
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List scripts ranked by number of mentions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::scripts_by_mention_count - List scripts ranked by number of mentions

=head1 VERSION

This document describes version 1.034 of App::lcpan::Cmd::scripts_by_mention_count (from Perl distribution App-lcpan), released on 2019-06-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List scripts ranked by number of mentions.

This shows the list of most mentioned scripts, that is, scripts who are
linked/referred to the most in PODs.

By default, each source module/script that mentions a script is counted as one
mention (C<--count-per content>). Use C<--count-per dist> to only count mentions
by modules/scripts from the same dist as one mention (so a script only gets a
maximum of 1 vote per dist). Use C<--count-per author> to only count mentions by
modules/scripts from the same author as one mention (so a script only gets a
maximum of 1 vote per mentioning author).

By default, only mentions from other authors are included. Use
C<--include-self-mentions> to also include mentions from the same author.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<count_per> => I<str> (default: "content")

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<include_self_mentions> => I<bool> (default: 0)

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

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
