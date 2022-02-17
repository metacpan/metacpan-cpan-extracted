package App::TaggedDirUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

#use File::chdir;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-23'; # DATE
our $DIST = 'App-TaggedDirUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to tagged directories',
};

our %argspecs_common = (
    prefixes => {
        summary => 'Locations to search for tagged directories',
        schema => ['array*', of=>'dirname*'],
        req => 1,
        pos => 0,
        slurpy => 1,
        description => <<'_',

Location(s) to search for tagged subdirectories, i.e. directories which have
some file with specific names in its root.

_
    },
);

$SPEC{list_tagged_dirs} = {
    v => 1.1,
    summary => 'Search tagged directories recursively in a list of places',
    description => <<'_',

Note: when a tagged dir is found, its contents are no longer recursed to search
for other tagged dirs.

_
    args => {
        %argspecs_common,
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        has_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'has_tag',
            schema => ['array*', of=>'str*'],
        },
        lacks_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'lacks_tag',
            schema => ['array*', of=>'str*'],
        },
        has_files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'has_file',
            schema => ['array*', of=>'filename*'],
        },
        lacks_files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'lacks_file',
            schema => ['array*', of=>'filename*'],
        },
    },
    examples => [
        {
            summary => 'How many datadirs are here?',
            src => '[[prog]] --has-tag datadir --lacks-file .git . | wc -l',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List all media tagged directories in all my external drives (show name as well as path)',
            src => '[[prog]] --has-tag media --lacks-file .git -l /media/budi /media/ujang',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Backup all my mediadirs to Google Drive',
            src => q{[[prog]] --has-tag media --lacks-file .git -l /media/budi /media/ujang | td map '"rclone copy -v -v $_->{abs_path} mygdrive:/backup/$_->{name}"' | bash},
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_tagged_dirs {
    require Cwd;
    require File::Basename;
    require File::Find;

    my %args = @_;
    @{ $args{prefixes} }
        or return [400, "Please specify one or more directories in 'prefixes'"];

    my @prefixes;
    for my $prefix (@{ $args{prefixes} }) {
        (-d $prefix) or do {
            log_error "Not a directory '$prefix', skip searching tagged dirs in this directory";
            next;
        };
        push @prefixes, $prefix;
    }

    my @rows;
    File::Find::find(
        {
            preprocess => sub {
                my $matches;
              FILTER: {
                    if ($args{has_tags}) {
                        for my $tag (@{ $args{has_tags} }) {
                            last FILTER unless -e ".tag-$tag";
                        }
                    }
                    if ($args{lacks_tags}) {
                        for my $tag (@{ $args{lacks_tags} }) {
                            last FILTER if -e ".tag-$tag";
                        }
                    }
                    if ($args{has_files}) {
                        for my $file (@{ $args{has_files} }) {
                            last FILTER unless -e $file;
                        }
                    }
                    if ($args{lacks_files}) {
                        for my $file (@{ $args{lacks_files} }) {
                            last FILTER if -e $file;
                        }
                    }
                    $matches++;
                }
                if ($matches) {
                    #log_trace "TMP: dir=%s", $File::Find::dir;
                    my $abs_path = Cwd::getcwd();
                    defined $abs_path or do {
                        log_fatal "Cant getcwd() in %s: %s", $File::Find::dir, $!;
                        die;
                    };
                    log_trace "%s matches", $abs_path;
                    push @rows, {
                        name => File::Basename::basename($abs_path),
                        path => $File::Find::dir,
                        abs_path => $abs_path,
                    };
                    return ();
                }
                log_trace "Recursing into $File::Find::dir ...";
                my @entries;
                for my $entry (@_) {
                    next if $args{lacks_files} && (grep { $_ eq $entry } @{ $args{lacks_files} });
                    push @entries, $entry;
                }
                return @entries;
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
# ABSTRACT: CLI utilities related to tagged directories

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TaggedDirUtils - CLI utilities related to tagged directories

=head1 VERSION

This document describes version 0.002 of App::TaggedDirUtils (from Perl distribution App-TaggedDirUtils), released on 2021-08-23.

=head1 SYNOPSIS

See CLIs included in this distribution.

=head1 DESCRIPTION

This distribution includes several utilities related to tagged directories:

=over

=item * L<list-tagged-dirs>

=back

A "tagged directory" is a directory which has one or more tags: usually empty
files called F<.tag-TAGNAME>, where I<TAGNAME> is some tag name.

You can backup, rsync, or do whatever you like with a tagged directory, just
like a normal filesystem directory. The utilities provided in this distribution
help you handle tagged directories.

=head1 FUNCTIONS


=head2 list_tagged_dirs

Usage:

 list_tagged_dirs(%args) -> [$status_code, $reason, $payload, \%result_meta]

Search tagged directories recursively in a list of places.

Note: when a tagged dir is found, its contents are no longer recursed to search
for other tagged dirs.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<has_files> => I<array[filename]>

=item * B<has_tags> => I<array[str]>

=item * B<lacks_files> => I<array[filename]>

=item * B<lacks_tags> => I<array[str]>

=item * B<prefixes>* => I<array[dirname]>

Locations to search for tagged directories.

Location(s) to search for tagged subdirectories, i.e. directories which have
some file with specific names in its root.


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

=head2 Why tagged directories?

With tagged directories, you can put them in various places and not just on a
single parent directory. For example:

 media/
   2020/
     media-2020a/ -> a tagged dir
       .tag-media
       ...
     media-2020b/ -> a tagged dir
       .tag-media
       ...
   2021/
     media-2021a/ -> a tagged dir
       .tag-media
       ...
   etc/
     foo -> a tagged dir
       .tag-media
       ...
     others/
       bar/ -> a tagged dir
         .tag-media
         ...

As an alternative, you can also create symlinks:

 all-media/
   media-2020a -> symlink to ../media/2020/media-2020a
   media-2020b -> symlink to ../media/2020/media-2020b
   media-2021a -> symlink to ../media/2021/media-2021a
   media-2021b -> symlink to ../media/2021/media-2021b
   foo -> symlink to ../media/etc/foo
   bar -> symlink to ../media/etc/others/bar

and process entries in all-media/.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-TaggedDirUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TaggedDirUtils>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TaggedDirUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
