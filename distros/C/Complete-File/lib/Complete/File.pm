package Complete::File;

our $DATE = '2016-10-20'; # DATE
our $VERSION = '0.42'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_file
                       complete_dir
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to files',
};

$SPEC{complete_file} = {
    v => 1.1,
    summary => 'Complete file and directory from local filesystem',
    args => {
        %arg_word,
        filter => {
            summary => 'Only return items matching this filter',
            description => <<'_',

Filter can either be a string or a code.

For string filter, you can specify a pipe-separated groups of sequences of these
characters: f, d, r, w, x. Dash can appear anywhere in the sequence to mean
not/negate. An example: `f` means to only show regular files, `-f` means only
show non-regular files, `drwx` means to show only directories which are
readable, writable, and executable (cd-able). `wf|wd` means writable regular
files or writable directories.

For code filter, you supply a coderef. The coderef will be called for each item
with these arguments: `$name`. It should return true if it wants the item to be
included.

_
            schema  => ['any*' => {of => ['str*', 'code*']}],
            tags => ['category:filtering'],
        },
        file_regex_filter => {
            summary => 'Filter shortcut for file regex',
            description => <<'_',

This is a shortcut for constructing a filter. So instead of using `filter`, you
use this option. This will construct a filter of including only directories or
regular files, and the file must match a regex pattern. This use-case is common.

_
            schema => 're*',
            tags => ['category:filtering'],
        },
        exclude_dir => {
            schema => 'bool*',
            description => <<'_',

This is also an alternative to specifying full `filter`. Set this to true if you
do not want directories.

If you only want directories, take a look at `complete_dir()`.

_
            tags => ['category:filtering'],
        },
        file_ext_filter => {
            schema => ['any*', of=>['re*', ['array*',of=>'str*']]],
            description => <<'_',

This is also an alternative to specifying full `filter` or `file_regex_filter`.
You can set this to a regex or a set of extensions to accept. Note that like in
`file_regex_filter`, directories of any name is also still allowed.

_
            tags => ['category:filtering'],
        },
        starting_path => {
            schema  => 'str*',
            default => '.',
        },
        handle_tilde => {
            schema  => 'bool',
            default => 1,
        },
        allow_dot => {
            summary => 'If turned off, will not allow "." or ".." in path',
            description => <<'_',

This is most useful when combined with `starting_path` option to prevent user
going up/outside the starting path.

_
            schema  => 'bool',
            default => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_file {
    require Complete::Path;
    require Encode;
    require File::Glob;

    my %args   = @_;
    my $word   = $args{word} // "";
    my $handle_tilde = $args{handle_tilde} // 1;
    my $allow_dot   = $args{allow_dot} // 1;

    # if word is starts with "~/" or "~foo/" replace it temporarily with user's
    # name (so we can restore it back at the end). this is to mimic bash
    # support. note that bash does not support case-insensitivity for "foo".
    my $result_prefix;
    my $starting_path = $args{starting_path} // '.';
    if ($handle_tilde && $word =~ s!\A(~[^/]*)/!!) {
        $result_prefix = "$1/";
        my @dir = File::Glob::glob($1); # glob will expand ~foo to /home/foo
        return [] unless @dir;
        $starting_path = Encode::decode('UTF-8', $dir[0]);
    } elsif ($allow_dot && $word =~ s!\A((?:\.\.?/+)+|/+)!!) {
        # just an optimization to skip sequences of '../'
        $starting_path = $1;
        $result_prefix = $1;
        $starting_path =~ s#/+\z## unless $starting_path =~ m!\A/!;
    }

    # bail if we don't allow dot and the path contains dot
    return [] if !$allow_dot &&
        $word =~ m!(?:\A|/)\.\.?(?:\z|/)!;

    # prepare list_func
    my $list = sub {
        my ($path, $intdir, $isint) = @_;
        opendir my($dh), $path or return undef;
        my @res;
        for (sort readdir $dh) {
            # skip . and .. if leaf is empty, like in bash
            next if ($_ eq '.' || $_ eq '..') && $intdir eq '';
            next if $isint && !(-d "$path/$_");
            push @res, Encode::decode('UTF-8', $_);
        }
        \@res;
    };

    # prepare filter_func

    # from the filter option
    my $filter;
    if ($args{filter} && !ref($args{filter})) {
        my @seqs = split /\s*\|\s*/, $args{filter};
        $filter = sub {
            my $name = shift;
            my @st = stat($name) or return 0;
            my $mode = $st[2];
            my $pass;
          SEQ:
            for my $seq (@seqs) {
                my $neg = sub { $_[0] };
                for my $c (split //, $seq) {
                    if    ($c eq '-') { $neg = sub { $_[0] ? 0 : 1 } }
                    elsif ($c eq 'r') { next SEQ unless $neg->($mode & 0400) }
                    elsif ($c eq 'w') { next SEQ unless $neg->($mode & 0200) }
                    elsif ($c eq 'x') { next SEQ unless $neg->($mode & 0100) }
                    elsif ($c eq 'f') { next SEQ unless $neg->($mode & 0100000)}
                    elsif ($c eq 'd') { next SEQ unless $neg->($mode & 0040000)}
                    else {
                        die "Unknown character in filter: $c (in $seq)";
                    }
                }
                $pass = 1; last SEQ;
            }
            $pass;
        };
    } elsif ($args{filter} && ref($args{filter}) eq 'CODE') {
        $filter = $args{filter};
    }

    # from the file_regex_filter option
    my $filter_fregex;
    if ($args{file_regex_filter}) {
        $filter_fregex = sub {
            my $name = shift;
            return 1 if -d $name;
            return 0 unless -f _;
            return 1 if $name =~ $args{file_regex_filter};
            0;
        };
    }

    # from the file_ext_filter option
    my $filter_fext;
    if ($args{file_ext_filter} && ref $args{file_ext_filter} eq 'Regexp') {
        $filter_fext = sub {
            my $name = shift;
            return 1 if -d $name;
            return 0 unless -f _;
            my $ext = $name =~ /\.(\w+)\z/ ? $1 : '';
            return 1 if $ext =~ $args{file_ext_filter};
            0;
        };
    } elsif ($args{file_ext_filter} && ref $args{file_ext_filter} eq 'ARRAY') {
        $filter_fext = sub {
            my $name = shift;
            return 1 if -d $name;
            return 0 unless -f _;
            my $ext = $name =~ /\.(\w+)\z/ ? $1 : '';
            if ($Complete::Common::OPT_CI) {
                $ext = lc($ext);
                for my $e (@{ $args{file_ext_filter} }) {
                    return 1 if $ext eq lc($e);
                }
            } else {
                for my $e (@{ $args{file_ext_filter} }) {
                    return 1 if $ext eq $e;
                }
            }
            0;
        };
    }

    # from _dir (used by complete_dir)
    my $filter_dir;
    if ($args{_dir}) {
        $filter_dir = sub { return 0 unless (-d $_[0]); 1 };
    }

    # from exclude_dir option
    my $filter_xdir;
    if ($args{exclude_dir}) {
        $filter_xdir = sub { return 0 if (-d $_[0]); 1 };
    }

    # final filter sub
    my $final_filter = sub {
        my $name = shift;
        if ($filter_dir)    { return 0 unless $filter_dir->($name)    }
        if ($filter_xdir)   { return 0 unless $filter_xdir->($name)   }
        if ($filter)        { return 0 unless $filter->($name)        }
        if ($filter_fregex) { return 0 unless $filter_fregex->($name) }
        if ($filter_fext)   { return 0 unless $filter_fext->($name)   }
        1;
    };

    Complete::Path::complete_path(
        word => $word,
        list_func => $list,
        is_dir_func => sub { -d $_[0] },
        filter_func => $final_filter,
        starting_path => $starting_path,
        result_prefix => $result_prefix,
    );
}

$SPEC{complete_dir} = do {
    my $spec = {%{ $SPEC{complete_file} }}; # shallow copy

    $spec->{summary} = 'Complete directory from local filesystem '.
        '(wrapper for complete_dir() that only picks directories)';
    $spec->{args} = { %{$spec->{args}} }; # shallow copy of args
    delete $spec->{args}{file_regex_filter};
    delete $spec->{args}{file_ext_filter};
    delete $spec->{args}{exclude_dir};

    $spec;
};
sub complete_dir {
    my %args = @_;

    complete_file(%args, _dir=>1);
}

1;
# ABSTRACT: Completion routines related to files

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::File - Completion routines related to files

=head1 VERSION

This document describes version 0.42 of Complete::File (from Perl distribution Complete-File), released on 2016-10-20.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_dir(%args) -> array

Complete directory from local filesystem (wrapper for complete_dir() that only picks directories).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_dot> => I<bool> (default: 1)

If turned off, will not allow "." or ".." in path.

This is most useful when combined with C<starting_path> option to prevent user
going up/outside the starting path.

=item * B<filter> => I<str|code>

Only return items matching this filter.

Filter can either be a string or a code.

For string filter, you can specify a pipe-separated groups of sequences of these
characters: f, d, r, w, x. Dash can appear anywhere in the sequence to mean
not/negate. An example: C<f> means to only show regular files, C<-f> means only
show non-regular files, C<drwx> means to show only directories which are
readable, writable, and executable (cd-able). C<wf|wd> means writable regular
files or writable directories.

For code filter, you supply a coderef. The coderef will be called for each item
with these arguments: C<$name>. It should return true if it wants the item to be
included.

=item * B<handle_tilde> => I<bool> (default: 1)

=item * B<starting_path> => I<str> (default: ".")

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (array)


=head2 complete_file(%args) -> array

Complete file and directory from local filesystem.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_dot> => I<bool> (default: 1)

If turned off, will not allow "." or ".." in path.

This is most useful when combined with C<starting_path> option to prevent user
going up/outside the starting path.

=item * B<exclude_dir> => I<bool>

This is also an alternative to specifying full C<filter>. Set this to true if you
do not want directories.

If you only want directories, take a look at C<complete_dir()>.

=item * B<file_ext_filter> => I<re|array[str]>

This is also an alternative to specifying full C<filter> or C<file_regex_filter>.
You can set this to a regex or a set of extensions to accept. Note that like in
C<file_regex_filter>, directories of any name is also still allowed.

=item * B<file_regex_filter> => I<re>

Filter shortcut for file regex.

This is a shortcut for constructing a filter. So instead of using C<filter>, you
use this option. This will construct a filter of including only directories or
regular files, and the file must match a regex pattern. This use-case is common.

=item * B<filter> => I<str|code>

Only return items matching this filter.

Filter can either be a string or a code.

For string filter, you can specify a pipe-separated groups of sequences of these
characters: f, d, r, w, x. Dash can appear anywhere in the sequence to mean
not/negate. An example: C<f> means to only show regular files, C<-f> means only
show non-regular files, C<drwx> means to show only directories which are
readable, writable, and executable (cd-able). C<wf|wd> means writable regular
files or writable directories.

For code filter, you supply a coderef. The coderef will be called for each item
with these arguments: C<$name>. It should return true if it wants the item to be
included.

=item * B<handle_tilde> => I<bool> (default: 1)

=item * B<starting_path> => I<str> (default: ".")

=item * B<word>* => I<str> (default: "")

Word to complete.

=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-File>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-File>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-File>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
