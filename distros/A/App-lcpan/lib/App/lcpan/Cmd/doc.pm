package App::lcpan::Cmd::doc;

use 5.010;
use strict;
use warnings;

use Encode qw(decode);

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-26'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.074'; # VERSION

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'Show POD documentation of module/POD/script',
    description => <<'_',

This command extracts module (.pm)/.pod/script from release tarballs and render
its POD documentation. Since the documentation is retrieved from the release
tarballs in the mirror, the module/.pod/script needs not be installed.

Note that currently this command has trouble finding documentation for core
modules because those are contained in perl release tarballs instead of release
tarballs of modules, and `lcpan` is currently not designed to work with those.

_
    args => {
        %App::lcpan::common_args,
        name => {
            summary => 'Module or script name',
            description => <<'_',

If the name matches both module name and script name, the module will be chosen.
To choose the script, use `--script` (`-s`).

_
            schema => 'str*',
            req => 1,
            pos => 0,
            completion => \&App::lcpan::_complete_content_package_or_script,
        },
        script => {
            summary => 'Look for script first',
            schema => ['bool', is=>1],
            cmdline_aliases => {s=>{}},
        },
        format => {
            schema => ['str*', in=>[qw/raw html man/]],
            default => 'man',
            cmdline_aliases => {
                raw => {
                    summary => 'Dump raw POD instead of rendering it',
                    is_flag => 1,
                    code => sub { $_[0]{format} = 'raw' },
                },
                r => {
                    summary => 'Same as --raw',
                    is_flag => 1,
                    code => sub { $_[0]{format} = 'raw' },
                },
                html => {
                    summary => 'Show HTML documentation in browser instead of rendering as man',
                    is_flag => 1,
                    code => sub { $_[0]{format} = 'html' },
                },
                man => {
                    summary => 'Read as manpage (the default)',
                    is_flag => 1,
                    code => sub { $_[0]{format} = 'man' },
                },
            },
            tags => ['category:output'],
        },
    },
    args_rels => {
    },
    examples => [
        {
            summary => 'Seach module/POD/script named Rinci',
            argv => ['Rinci'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Specifically choose .pm file',
            argv => ['Rinci.pm'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Specifically choose .pod file',
            argv => ['Rinci.pod'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Look for script first named strict',
            argv => ['-s', 'strict'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Dump the raw POD instead of rendering it',
            argv => ['--raw', 'Text::Table::Tiny'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        # filter arg: rel to pick a specific release file
    ],
    deps => {
        all => [
            {prog => 'pod2man'},  # XXX only when format=man
            {prog => 'pod2html'}, # XXX only when format=html
        ],
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $name = $args{name};
    my $ext = '';
    $name =~ s!/!::!g;
    $ext = $1 if $name =~ s/\.(pm|pod)\z//;

    my @look_order;
    if ($args{script}) {
        @look_order = ('script', 'module');
    } else {
        @look_order = ('module', 'script');
    }

    my $row;
  LOOK:
    for my $look (@look_order) {
        my @where;
        my @bind = ($name);
        if ($look eq 'module') {

            push @where, "package=?";
            if ($ext eq 'pm') {
                push @where, "path LIKE '%.pm'";
            } elsif ($ext eq 'pod') {
                push @where, "path LIKE '%.pod'";
            }
            push @where, ("NOT(file.name LIKE '%-Lumped-%')"); # tmp
            $row = $dbh->selectrow_hashref("SELECT
  content.path content_path,
  file.cpanid author,
  file.name release
FROM content
LEFT JOIN file ON content.file_id=file.id
".(@where ? " WHERE ".join(" AND ", @where) : "")."
ORDER BY content.size DESC
LIMIT 1", {}, @bind);
            last LOOK if $row;

            if ($ext eq 'pod') {
                # .pod doesn't always declare package so we also try to guess
                # from content path
                $name =~ s!::!/!g; $name .= ".pod";
                @where = ("content.path LIKE ?");
                push @where, ("NOT(file.name LIKE '%-Lumped-%')"); # tmp
                @bind = ("%$name");

                my $sth = $dbh->prepare("SELECT
  content.path content_path,
  file.cpanid author,
  file.name release
FROM content
LEFT JOIN file ON content.file_id=file.id
".(@where ? " WHERE ".join(" AND ", @where) : "")."
ORDER BY content.size DESC");
                $sth->execute(@bind);
                while (my $r = $sth->fetchrow_hashref) {
                    if ($r->{content_path} =~ m!^[^/]+/\Q$name\E$!) {
                        $row = $r;
                        last LOOK;
                    }
                }
            }

        } elsif ($look eq 'script') {

            push @where, "script.name=?";
            push @where, ("NOT(file.name LIKE '%-Lumped-%')"); # tmp
            $row = $dbh->selectrow_hashref("SELECT
  content.path content_path,
  file.cpanid author,
  file.name release
FROM script
LEFT JOIN file ON script.file_id=file.id
LEFT JOIN content ON script.content_id=content.id
".(@where ? " WHERE ".join(" AND ", @where) : "")."
ORDER BY content.size DESC
LIMIT 1", {}, @bind);
            last LOOK if $row;

        }
    }

    return [404, "No such module/POD/script"] unless $row;

    my $path = App::lcpan::_fullpath(
        $row->{release}, $state->{cpan}, $row->{author});

    # XXX needs to be refactored into common code
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

    if ($content =~ /^=encoding\s+(utf-?8)/im) {
        # doesn't seem necessary
        #$content = decode('utf8', $content, Encode::FB_CROAK);
    }

    if ($args{format} eq 'raw') {
        return [200, "OK", $content, {
            "cmdline.page_result"=>1,
            'cmdline.skip_format'=>1,
        }];
    } elsif ($args{format} eq 'html') {
        require Browser::Open;
        require File::Slurper;
        require File::Temp;
        require File::Util::Tempdir;

        my $tmpdir = File::Util::Tempdir::get_tempdir();
        my $cachedir = File::Temp::tempdir(CLEANUP => 1);
        my $name = $name; $name =~ s/:+/_/g;
        my ($infh, $infile) = File::Temp::tempfile(
            "$name.XXXXXXXX", DIR=>$tmpdir, SUFFIX=>".pod");
        my $outfile = "$infile.html";
        File::Slurper::write_binary($infile, $content);
        system(
            "pod2html",
            "--infile", $infile,
            "--outfile", $outfile,
            "--cachedir", $cachedir,
        );
        return [500, "Can't pod2html: $!"] if $?;
        my $err = Browser::Open::open_browser("file:$outfile");
        return [500, "Can't open browser"] if $err;
        [200];
    } else {
        return [200, "OK", $content, {
            "cmdline.page_result"=>1,
            "cmdline.pager"=>"pod2man -u | man -l -"}];
    }
}

1;
# ABSTRACT: Show POD documentation of module/POD/script

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::doc - Show POD documentation of module/POD/script

=head1 VERSION

This document describes version 1.074 of App::lcpan::Cmd::doc (from Perl distribution App-lcpan), released on 2023-09-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show POD documentation of moduleE<sol>PODE<sol>script.

Examples:

=over

=item * Seach moduleE<sol>PODE<sol>script named Rinci:

 handle_cmd(name => "Rinci");

=item * Specifically choose .pm file:

 handle_cmd(name => "Rinci.pm");

=item * Specifically choose .pod file:

 handle_cmd(name => "Rinci.pod");

=item * Look for script first named strict:

 handle_cmd(name => "strict", script => 1);

=item * Dump the raw POD instead of rendering it:

 handle_cmd(name => "Text::Table::Tiny", format => "raw");

=back

This command extracts module (.pm)/.pod/script from release tarballs and render
its POD documentation. Since the documentation is retrieved from the release
tarballs in the mirror, the module/.pod/script needs not be installed.

Note that currently this command has trouble finding documentation for core
modules because those are contained in perl release tarballs instead of release
tarballs of modules, and C<lcpan> is currently not designed to work with those.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<format> => I<str> (default: "man")

(No description)

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<name>* => I<str>

Module or script name.

If the name matches both module name and script name, the module will be chosen.
To choose the script, use C<--script> (C<-s>).

=item * B<script> => I<bool>

Look for script first.

=item * B<update_db_schema> => I<bool> (default: 1)

Whether to update database schema to the latest.

By default, when the application starts and reads the index database, it updates
the database schema to the latest if the database happens to be last updated by
an older version of the application and has the old database schema (since
database schema is updated from time to time, for example at 1.070 the database
schema is at version 15).

When you disable this option, the application will not update the database
schema. This option is for testing only, because it will probably cause the
application to run abnormally and then die with a SQL error when reading/writing
to the database.

Note that in certain modes e.g. doing tab completion, the application also will
not update the database schema.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
