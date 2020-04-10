package App::ManagePoolStyleRepo;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-10'; # DATE
our $DIST = 'App-ManagePoolStyleRepo'; # DIST
our $VERSION = '0.001'; # VERSION

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

my $re_filename_unix = $Regexp::Pattern::Path::RE{filename_unix}{pat};

our %SPEC;

our %args_common = (
    repo_path => {
        schema => 'dirname*',
        req => 1,
        pos => 0,
        summary => 'Repo directory',
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
    my %args = @_;

    my $q_lc; $q_lc = lc $args{q} if defined $args{q};
    my $searchable_fields = $args{_searchable_fields} // ['filename', 'title'];

    local $CWD = $args{repo_path};

    my @rows;

  POOL:
    {
        last unless -d "pool";
        local $CWD = "pool";
        for my $item_path (glob "*") {
            my $row;
            $row = get_item_metadata(item_path=>$item_path, _skip_cd=>1);
            $row->{dir} = "";
            push @rows, $row;
        }
    }

  POOL1:
    {
        last unless -d "pool1";
        local $CWD = "pool1";
        for my $dir1 (grep {-d} glob "*") {
            local $CWD = $dir1;
            for my $item_path (glob "*") {
                my $row;
                $row = get_item_metadata(item_path=>$item_path, _skip_cd=>1);
                $row->{dir} = $dir1;
                push @rows, $row;
            }
        }
    }

  POOL2:
    {
        last unless -d "pool2";
        local $CWD = "pool2";
        for my $dir1 (grep {-d} glob "*") {
            local $CWD = $dir1;
            for my $dir2 (grep {-d} glob "*") {
                local $CWD = $dir2;
                for my $item_path (glob "*") {
                    my $row;
                    $row = get_item_metadata(item_path=>$item_path, _skip_cd=>1);
                    $row->{dir} = "$dir1/$dir2";
                    push @rows, $row;
                }
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
            my $target = "../../pool" . (length $item->{dir} ? "/$item->{dir}" : "") . "/$item->{filename}";
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
                my $target = "../../".("../" x $num_level) . "pool" . (length $item->{dir} ? "/$item->{dir}" : "") . "/$item->{filename}";
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

This document describes version 0.001 of App::ManagePoolStyleRepo (from Perl distribution App-ManagePoolStyleRepo), released on 2020-04-10.

=head1 FUNCTIONS


=head2 get_item_metadata

Usage:

 get_item_metadata(%args) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<item_path>* => I<filename>


=back

Return value:  (any)



=head2 list_items

Usage:

 list_items(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<has_tags> => I<array[str]>

=item * B<lacks_tags> => I<array[str]>

=item * B<q> => I<str>

Search query.

=item * B<repo_path>* => I<dirname>

Repo directory.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 update_index

Usage:

 update_index(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<repo_path>* => I<dirname>

Repo directory.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
