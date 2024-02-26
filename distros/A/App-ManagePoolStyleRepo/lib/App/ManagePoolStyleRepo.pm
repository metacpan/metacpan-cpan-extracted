package App::ManagePoolStyleRepo;

use 5.010001;
use strict;
use warnings;
use Log::ger;
use Log::ger::For::Builtins qw(rename system);

use Cwd;
use File::chdir;
use File::Slurper qw(read_text);
use Hash::Subset qw(hash_subset);
use Regexp::Pattern::Path;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'App-ManagePoolStyleRepo'; # DIST
our $VERSION = '0.003'; # VERSION

my $re_filename_unix = $Regexp::Pattern::Path::RE{filename_unix}{pat};

our %SPEC;

our %args_common = (
    repo_path => {
        schema => 'dirname*',
        req => 1,
        pos => 0,
        summary => 'Repo directory',
    },
    pool_pattern => {
        schema => 're*',
        default => qr/\Apool(?:\..+)?\z/,
        description => <<'_',

By default, `pool` and `pool.*` subdirectory under the repo are searched for
items. You can customize using this option. But note that `pool1_pattern` and
`pool2_pattern` options have precedence over this.

_
    },
    pool1_pattern => {
        schema => 're*',
        default => qr/\Apool1(?:\..+)?\z/,
        description => <<'_',

By default, `pool1` and `pool1.*` subdirectories under the repo are searched for
items under a layer of intermediate subdirectories. You can customize using this
option. But note that `pool2_pattern` option has precedence over this.

_
    },
    pool2_pattern => {
        schema => 're*',
        default => qr/\Apool2(?:\..+)?\z/,
        description => <<'_',

By default, `pool2` and `pool2.*` subdirectories under the repo are searched for
items. You can customize using this option.

_
    },
);

our %argopt_detail = (
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

$SPEC{get_item_metadata} = {
    v => 1.1,
    args => {
        item_path => {
            schema => 'filename*',
        req => 1,
            pos => 0,
        },
    },
    result_naked => 1,
};
sub get_item_metadata {
    my %args = @_;
    my $path = $args{item_path};

    my $filename;
    if ($args{_skip_cd}) {
        $filename = $path;
    } else {
        my $abs_path = Cwd::abs_path($path);
        ($filename = $abs_path) =~ s!./!!;
    }

    my $res = {};
    $res->{filename} = $filename;
    $res->{title} = $filename;

    if (-d $path) {
        local $CWD = $path;
        if (-f ".title") {
            (my $title = read_text(".title")) =~ s/\R+//g;
            die "$path: Invalid title in .title: invalid filename"
                unless $title =~ $re_filename_unix;
            $res->{title} = $title;
        }
        my @tag_files = glob ".tag-*";
        $res->{tags} = [map { my $t = $_; $t =~ s/\A\.tag-//; $t } @tag_files] if @tag_files;
    } else {
    }
    $res;
}

$SPEC{list_items} = {
    v => 1.1,
    args => {
        %args_common,
        %argopt_detail,

        has_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'has_tag',
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
        },
        lacks_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'lacks_tag',
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
        },
        q => {
            summary => 'Search query',
            schema => 'str*',
            pos => 1,
            tags => ['category:filtering'],
        },

        _searchable_fields => {
            schema => ['array*', of=>'str*'],
            default => ['filename', 'title'],
            tags => ['hidden'],
        },
    },
    features => {
    },
};
sub list_items {
    require File::Util::Test;

    my %args = @_;
    my $pool_pattern  = $args{pool_pattern}  // qr/\Apool(?:\..+)?\z/;
    my $pool1_pattern = $args{pool1_pattern} // qr/\Apool1(?:\..+)?\z/;
    my $pool2_pattern = $args{pool2_pattern} // qr/\Apool2(?:\..+)?\z/;

    my $q_lc; $q_lc = lc $args{q} if defined $args{q};
    my $searchable_fields = $args{_searchable_fields} // ['filename', 'title'];

    local $CWD = $args{repo_path};

    my @rows;

    my @dir_entries = File::Util::Test::get_dir_entries();

  POOL2:
    {
        for my $pool_dir (grep { $_ =~ $pool2_pattern } @dir_entries) {
            local $CWD = $pool_dir;
            for my $dir1 (grep {-d} glob "*") {
                local $CWD = $dir1;
                for my $dir2 (grep {-d} glob "*") {
                    local $CWD = $dir2;
                    for my $item_path (glob "*") {
                        my $row;
                        $row = get_item_metadata(item_path=>$item_path, _skip_cd=>1);
                        $row->{dir} = "$pool_dir/$dir1/$dir2";
                        push @rows, $row;
                    }
                }
            }
        }
    }

  POOL1:
    {
        for my $pool_dir (grep { $_ =~ $pool1_pattern } @dir_entries) {
            local $CWD = $pool_dir;
            for my $dir1 (grep {-d} glob "*") {
                local $CWD = $dir1;
                for my $item_path (glob "*") {
                    my $row;
                    $row = get_item_metadata(item_path=>$item_path, _skip_cd=>1);
                    $row->{dir} = "$pool_dir/$dir1";
                    push @rows, $row;
                }
            }
        }
    }

  POOL:
    {
        for my $pool_dir (grep { $_ =~ $pool_pattern } @dir_entries) {
            local $CWD = $pool_dir;
            for my $item_path (glob "*") {
                my $row;
                $row = get_item_metadata(item_path=>$item_path, _skip_cd=>1);
                $row->{dir} = $pool_dir;
                push @rows, $row;
            }
        }
    }

  FILTER: {
        my @frows;
      ROW:
        for my $row (@rows) {
            if ($args{has_tags}) {
                my $matches;
                for my $tag (@{ $args{has_tags} }) {
                    do { $matches++; last } if $row->{tags} &&
                        grep { $tag eq $_ } @{ $row->{tags} };
                }
                next ROW unless $matches;
            }
            if ($args{lacks_tags}) {
                my $matches = 1;
                for my $tag (@{ $args{lacks_tags} }) {
                    do { $matches = 0; last } if $row->{tags} &&
                        grep { $tag eq $_ } @{ $row->{tags} };
                }
                next ROW unless $matches;
            }
            if (defined $q_lc) {
                my $matches;
                for my $field (@$searchable_fields) {
                    do { $matches++; last } if defined $row->{$field} && index(lc($row->{$field}), $q_lc) >= 0;
                }
                next ROW unless $matches;
            }
            push @frows, $row;
        }
        @rows = @frows;
    }

    unless ($args{detail}) {
        @rows = map { $_->{title} } @rows;
    }

    [200, "OK", \@rows];
}

$SPEC{update_index} = {
    v => 1.1,
    args => {
        %args_common,
    },
    features => {
        #dry_run => 1,
    },
};
sub update_index {
    require File::Path;
    require File::Temp;

    my %args = @_;

    my $res = list_items(
        %args,
        detail=>1,
    );
    return $res unless $res->[0] == 200;

    local $CWD = $args{repo_path};
    my $tmpdir = File::Temp::tempdir("index.tmp.XXXXXXXX", DIR => $args{repo_path});
    (my $tmpname = $tmpdir) =~ s!.+/!!;
    $CWD = $tmpname;

  CREATE_TITLE_INDEX:
    {
        mkdir "by-title";
        local $CWD = "by-title";
        for my $item (@{ $res->[2] }) {
            my $target = "../../$item->{dir}/$item->{filename}";
            my $link   = $item->{title};
            symlink $target, $link or warn "Can't symlink $link -> $target: $!";
        }
    } # CREATE_TITLE_INDEX

  CREATE_TAG_INDEX:
    {
        mkdir "by-tag";
        local $CWD = "by-tag";

        # collect all tags
        my %tags;
        for my $item (@{ $res->[2] }) {
            next unless $item->{tags};
            for my $tag (@{ $item->{tags} }) {
                (my $tagdir = $tag) =~ s!-+!/!g;
                File::Path::mkpath($tagdir) unless $tags{$tag}++;
                my $num_level = 1; $num_level++ while $tagdir =~ m!/!g;
                my $target = "../../".("../" x $num_level).$item->{dir}."/$item->{filename}";
                my $link = "$tagdir/$item->{title}";
                symlink $target, $link or warn "Can't symlink $link -> $target: $!";
            }
        }

    } # CREATE_TAG_INDEX

    $CWD = "..";
    File::Path::rmtree("index");
    rename $tmpname, "index" or die "Can't rename $tmpname -> index: $!";
    #system "mv", $tmpname, "index" or die "Can't move $tmpname -> index: $!";

    [200];
}

1;
# ABSTRACT: Manage pool-style repo directory

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ManagePoolStyleRepo - Manage pool-style repo directory

=head1 VERSION

This document describes version 0.003 of App::ManagePoolStyleRepo (from Perl distribution App-ManagePoolStyleRepo), released on 2023-11-20.

=head1 FUNCTIONS


=head2 get_item_metadata

Usage:

 get_item_metadata(%args) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<item_path>* => I<filename>

(No description)


=back

Return value:  (any)



=head2 list_items

Usage:

 list_items(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<has_tags> => I<array[str]>

(No description)

=item * B<lacks_tags> => I<array[str]>

(No description)

=item * B<pool1_pattern> => I<re> (default: qr(\Apool1(?:\..+)?\z))

By default, C<pool1> and C<pool1.*> subdirectories under the repo are searched for
items under a layer of intermediate subdirectories. You can customize using this
option. But note that C<pool2_pattern> option has precedence over this.

=item * B<pool2_pattern> => I<re> (default: qr(\Apool2(?:\..+)?\z))

By default, C<pool2> and C<pool2.*> subdirectories under the repo are searched for
items. You can customize using this option.

=item * B<pool_pattern> => I<re> (default: qr(\Apool(?:\..+)?\z))

By default, C<pool> and C<pool.*> subdirectory under the repo are searched for
items. You can customize using this option. But note that C<pool1_pattern> and
C<pool2_pattern> options have precedence over this.

=item * B<q> => I<str>

Search query.

=item * B<repo_path>* => I<dirname>

Repo directory.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 update_index

Usage:

 update_index(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<pool1_pattern> => I<re> (default: qr(\Apool1(?:\..+)?\z))

By default, C<pool1> and C<pool1.*> subdirectories under the repo are searched for
items under a layer of intermediate subdirectories. You can customize using this
option. But note that C<pool2_pattern> option has precedence over this.

=item * B<pool2_pattern> => I<re> (default: qr(\Apool2(?:\..+)?\z))

By default, C<pool2> and C<pool2.*> subdirectories under the repo are searched for
items. You can customize using this option.

=item * B<pool_pattern> => I<re> (default: qr(\Apool(?:\..+)?\z))

By default, C<pool> and C<pool.*> subdirectory under the repo are searched for
items. You can customize using this option. But note that C<pool1_pattern> and
C<pool2_pattern> options have precedence over this.

=item * B<repo_path>* => I<dirname>

Repo directory.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

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

This software is copyright (c) 2023, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=cut
