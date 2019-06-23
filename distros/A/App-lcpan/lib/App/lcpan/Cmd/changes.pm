package App::lcpan::Cmd::changes;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '1.034'; # VERSION

use 5.010;
use strict;
use warnings;

use Encode qw(decode);

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'Show Changes of distribution/module',
    description => <<'_',

This command will find a file named Changes/CHANGES/ChangeLog or other similar
name in the top-level directory inside the release tarballs and show it.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mod_or_dist_or_script_args,
        #parse => {
        #    summary => 'Parse with CPAN::Changes',
        #    schema => 'bool',
        #}.
    },
    examples => [
        {
            summary => 'Use module name',
            argv => ['Data::CSel::Parser'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        #{
        #    summary => 'Use dist name, parse',
        #    argv => ['--parse', 'App-PMUtils'],
        #    test => 0,
        #    'x.doc.show_result' => 0,
        #},
    ],
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $mod_or_dist_or_script = $args{module_or_dist_or_script};
    $mod_or_dist_or_script =~ s!/!::!g; # XXX this should be done by coercer

    my @join;
    my @where;
    my @bind;

    my @file_ids;
    {
        # search in module first
        unless ($mod_or_dist_or_script =~ /-/) {
            my $sth = $dbh->prepare("SELECT file_id FROM module WHERE name=?");
            $sth->execute($mod_or_dist_or_script);
            while (my ($e) = $sth->fetchrow_array) {
                push @file_ids, $e;
            }
        }
        # search in dist or script
        unless ($mod_or_dist_or_script =~ /::/) {
            my $dist_found;
            my $sth = $dbh->prepare("SELECT file_id FROM dist WHERE name=? ORDER BY version_numified DESC LIMIT 1");
            $sth->execute($mod_or_dist_or_script);
            while (my ($e) = $sth->fetchrow_array) {
                $dist_found++;
                push @file_ids, $e;
            }

            unless ($dist_found) {
                my $sth = $dbh->prepare("SELECT file_id FROM script WHERE name=?");
                $sth->execute($mod_or_dist_or_script);
                while (my ($e) = $sth->fetchrow_array) {
                    push @file_ids, $e;
                }
            }
        }

        return [404, "No such module/dist/script"] unless @file_ids;
        push @where, "file.id IN (".join(",", @file_ids).")";
    }

    my $sql = "SELECT
  content.path content_path,
  file.cpanid author,
  file.name release
FROM content
LEFT JOIN file ON content.file_id=file.id
".(@join  ? join(" ", @join) : "")."
".(@where ? " WHERE ".join(" AND ", @where) : "")."
ORDER BY content.path";
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);

    my $first_row;
    while (my $row = $sth->fetchrow_hashref) {
        $first_row //= $row;
        next unless $row->{content_path} =~ m!\A
                                              (?:[^/]+/)?
                                              (changes|changelog)
                                              (?:\.(\w+))?\z!ix;
        # XXX handle YAML file
        my $path = App::lcpan::_fullpath(
            $row->{release}, $state->{cpan}, $row->{author});

        # XXX needs to be refactored into common code (see also doc subcommand)
        my $content;
        if ($path =~ /\.zip$/i) {
            require Archive::Zip;
            my $zip = Archive::Zip->new;
            $zip->read($path) == Archive::Zip::AZ_OK()
                or return [500, "Can't read zip file '$path'"];
            $content = $zip->contents($row->{content_path});
        } else {
            require Archive::Tar;
            my $tar;
            eval {
                $tar = Archive::Tar->new;
                $content = $tar->read($path); # can still die untrapped when out of mem
            };
            return [500, "Can't read tar file '$path': $@"] if $@;
            my ($obj) = $tar->get_files($row->{content_path});
            $content = $obj->get_content;
        }

        return [200, "OK", $content, {
            'func.content_path' => $row->{content_path},
            'cmdline.skip_format'=>1,
            "cmdline.page_result"=>1,
        }];
    }

    if ($first_row) {
        return [404, "No Changes file found in $first_row->{release}"];
    } else {
        return [404, "No such module or dist"];
    }
}

1;
# ABSTRACT: Show Changes of distribution/module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::changes - Show Changes of distribution/module

=head1 VERSION

This document describes version 1.034 of App::lcpan::Cmd::changes (from Perl distribution App-lcpan), released on 2019-06-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Show Changes of distribution/module.

Examples:

=over

=item * Use module name:

 handle_cmd( module_or_dist_or_script => "Data::CSel::Parser");

=back

This command will find a file named Changes/CHANGES/ChangeLog or other similar
name in the top-level directory inside the release tarballs and show it.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<module_or_dist_or_script>* => I<str>

Module or dist or script name.

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
