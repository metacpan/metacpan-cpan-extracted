package App::DataDirUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use File::chdir;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-23'; # DATE
our $DIST = 'App-DataDirUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => '(DEPRECATED) CLI utilities related to datadirs',
};

our %argspecs_common = (
    prefixes => {
        summary => 'Locations to find datadirs',
        schema => ['array*', of=>'dirname*'],
        req => 1,
        pos => 0,
        slurpy => 1,
        description => <<'_',

Directory name(s) to search for "datadirs", i.e. directories which have
`.tag-datadir` file in its root.

_
    },
);

$SPEC{list_datadirs} = {
    v => 1.1,
    summary => 'Search datadirs recursively in a list of directory names',
    description => <<'_',

Note: when a datadir is found, its contents are no longer recursed to search for
other datadirs.

_
    args => {
        %argspecs_common,
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        skip_git => {
            summary => 'Do not recurse into .git directory',
            schema => 'bool*',
            default => 1,
        },
    },
    examples => [
        {
            summary => 'How many datadirs are here?',
            src => '[[prog]] . | wc -l',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List all datadirs in all my external drives (show name as well as path)',
            src => '[[prog]] /media/budi /media/ujang -l',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Backup all my datadirs to Google Drive',
            src => q{[[prog]] /media/budi /media/ujang -l | td map '"rclone copy -v -v $_->{abs_path} mygdrive:/backup/$_->{name}"' | bash},
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_datadirs {
    require Cwd;
    require File::Basename;
    require File::Find;

    my %args = @_;
    @{ $args{prefixes} }
        or return [400, "Please specify one or more directories in 'prefixes'"];

    my @prefixes;
    for my $prefix (@{ $args{prefixes} }) {
        (-d $prefix) or do {
            log_error "Not a directory '$prefix', skip searching datadirs in this directory";
            next;
        };
        push @prefixes, $prefix;
    }

    my @rows;
    File::Find::find(
        {
            preprocess => sub {
                if (-f ".tag-datadir") {
                    #log_trace "TMP: dir=%s", $File::Find::dir;
                    my $abs_path = Cwd::getcwd();
                    defined $abs_path or do {
                        log_fatal "Cant getcwd() in %s: %s", $File::Find::dir, $!;
                        die;
                    };
                    log_trace "%s is a datadir", $abs_path;
                    push @rows, {
                        name => File::Basename::basename($abs_path),
                        path => $File::Find::dir,
                        abs_path => $abs_path,
                    };
                    return ();
                }
                log_trace "Recursing into $File::Find::dir ...";
                if ($args{skip_git}) {
                    @_ = grep { $_ ne '.git' } @_;
                }
                return @_;
            },
            wanted => sub {
            },
        },
        @prefixes,
    );

    unless ($args{detail}) {
        @rows = map { $_->{abs_path} } @rows;
    }

    [200, "OK", \@rows, {'table.fields'=>[qw/name path abs_path/]}];
}

1;
# ABSTRACT: (DEPRECATED) CLI utilities related to datadirs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DataDirUtils - (DEPRECATED) CLI utilities related to datadirs

=head1 VERSION

This document describes version 0.003 of App::DataDirUtils (from Perl distribution App-DataDirUtils), released on 2021-08-23.

=head1 DEPRECATION NOTICE

This distribution is deprecated in favor of the more general
L<App::TaggedDirUtils>.

=head1 SYNOPSIS

See CLIs included in this distribution.

=head1 DESCRIPTION

This distribution includes several utilities related to datadirs:

=over

=item * L<list-datadirs>

=back

A "datadir" is a directory which has a (usually empty) file called
F<.tag-datadir>. A datadir usually does not contain other datadirs.

You can backup, rsync, or do whatever you like with a datadir, just like a
normal filesystem directory. The utilities provided in this distribution help
you handle datadirs.

=head1 FUNCTIONS


=head2 list_datadirs

Usage:

 list_datadirs(%args) -> [$status_code, $reason, $payload, \%result_meta]

Search datadirs recursively in a list of directory names.

Note: when a datadir is found, its contents are no longer recursed to search for
other datadirs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<prefixes>* => I<array[dirname]>

Locations to find datadirs.

Directory name(s) to search for "datadirs", i.e. directories which have
C<.tag-datadir> file in its root.

=item * B<skip_git> => I<bool> (default: 1)

Do not recurse into .git directory.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 FAQ

=head2 Why datadir?

With tagged directories, you can put them in various places and not just on a
single parent directory. For example:

 media/
   2020/
     media-2020a/ -> a datadir
     media-2020b/ -> a datadir
   2021/
     media-2021a/ -> a datadir
   etc/
     foo -> a datadir
     others/
       bar/ -> a datadir

As an alternative, you can also create symlinks:

 all-media/
   media-2020a -> symlink to ../media/2020/media-2020a
   media-2020b -> symlink to ../media/2020/media-2020b
   media-2021a -> symlink to ../media/2021/media-2021a
   media-2021b -> symlink to ../media/2021/media-2021b
   foo -> symlink to ../media/etc/foo
   bar -> symlink to ../media/etc/others/bar

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DataDirUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DataDirUtils>.

=head1 SEE ALSO

L<App::TaggedDirUtils> is the more general utility.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DataDirUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
