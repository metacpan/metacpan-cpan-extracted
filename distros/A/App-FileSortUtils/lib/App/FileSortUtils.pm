package App::FileSortUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
use Fcntl ':mode';
use File::chdir;
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-10-31'; # DATE
our $DIST = 'App-FileSortUtils'; # DIST
our $VERSION = '0.005'; # VERSION

our %SPEC;

my @file_types = qw(file dir);

my @file_fields = qw(name size mtime ctime);

our %argspecs_common = (
    dir => {
        summary => 'Directory to sort files of, defaults to current directory',
        schema => 'dirname::default_curdir',
        pos => 0,
        tags => ['category:input'],
    },

    type => {
        summary => 'Only include files of certain type',
        schema => ['str*', in=>\@file_types],
        cmdline_aliases => {
            t => {},
            f => {summary=>'Shortcut for `--type=file`', is_flag=>1, code=>sub { $_[0]{type} = 'file' }},
            d => {summary=>'Shortcut for `--type=dir`' , is_flag=>1, code=>sub { $_[0]{type} = 'dir'  }},
        },
        tags => ['category:filtering'],
    },

    detail => {
        schema => 'true*',
        cmdline_aliases => {l=>{}},
        tags => ['category:output'],
    },
    num_results => {
        summary => 'Number of results to return',
        schema => 'uint*',
        cmdline_aliases => {n=>{}},
    },
    num_ranks => {
        summary => 'Number of ranks to return',
        schema => 'uint*',
        description => <<'MARKDOWN',

Difference between `num_results` and `num_ranks`: `num_results` (`-n` option)
specifies number of results regardless of ranks while `num_ranks` (`-N` option)
returns number of ranks. For example, if sorting is by reverse size and if
`num_results` is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With `num_ranks` set to 1, both files
will be returned because are they both rank #1.

MARKDOWN
        cmdline_aliases => {N=>{}},
    },
);

our %argspecs_sort = (
    by_code => {
        summary => 'Perl code to sort',
        schema => 'code_from_str*',
        tags => ['category:sorting'],
    },
    by_sortsub => {
        summary => 'Sort::Sub routine name to sort',
        schema =>'str*',
        'x.completion' => ['sortsub_spec'],
        tags => ['category:sorting'],
    },
    sortsub_args => {
        summary => 'Arguments to pass to Sort::Sub routine',
        schema => ['hash*', of=>'str*'],
    },
    by_field => {
        summary => 'Field name to sort against',
        schema => ['str*', in=>\@file_fields],
        tags => ['category:sorting'],
    },
    reverse => {
        summary => 'Reverse order of sorting',
        schema => 'true*',
        cmdline_aliases => {r=>{}},
        tags => ['category:sorting'],
    },
    key => {
        summary => 'Perl code to generate key to sort against',
        schema => 'code_from_str*',
        description => <<'MARKDOWN',

If `key` option is not specified, then: 1) if sorting is `by_code` then the code
will receive files as records (hashes) with keys like `name`, `size`, etc; 2) if
sorting is `by_field` then the associated field is used as key; 3) if sorting is
`by_sortsub` then by default the `name` field will be used as the key.

To select a field, use this:

    '$_->{FIELDNAME}'

for example:

    '$_->{size}'

Another example, to generate length of name as key:

    'length($_->{name})'

MARKDOWN
            tags => ['category:sorting'],
    },
);

our %argspec_ignore_case = (
    ignore_case => {
        schema => 'bool*',
        cmdline_aliases => {i=>{}},
        tags => ['category:sorting'],
    },
);

$SPEC{sort_files} = {
    v => 1.1,
    summary => 'Sort files in a directory and display the result in a flexible way',
    description => <<'MARKDOWN',


MARKDOWN
    args => {
        %argspecs_common,
        %argspecs_sort,
    },
    args_rels => {
        'choose_one&' => [
            [qw/by_field by_sortsub by_code/],
            [qw/num_results num_ranks/],
        ],
    },
};
sub sort_files {
    my %args = @_;

    my $dir = $args{dir} // '.';
    opendir my $dh, $dir or return [500, "Can't opendir '$dir': $!"];
    my @files;
  GET_FILES: {
        local $CWD = $dir;
      FILE:
        while (defined(my $e = readdir $dh)) {
            next if $e eq '.' || $e eq '..';
            my $rec = {name=>$e};
            my @st = lstat $e or do {
                warn "Can't stat '$e' in '$dir': $!, skipped";
                next;
            };
            $rec->{size} = $st[7];
            $rec->{mtime} = $st[9];
            $rec->{ctime} = $st[10];
            $rec->{mode} = $st[2];
          FILTER: {
                if (defined $args{type}) {
                    if ($args{type} eq 'file') {
                        unless ($rec->{mode} & S_IFREG) {
                            log_trace "File '$e' in '$dir': not a regular file, skipped";
                            next FILE;
                        }
                    } elsif ($args{type} eq 'dir') {
                        unless ($rec->{mode} & S_IFDIR) {
                            log_trace "File '$e' in '$dir': not a directory, skipped";
                            next FILE;
                        }
                    } else {
                        return [400, "Invalid value of type '$args{type}'"];
                    }
                }
            }

            push @files, $rec;
        }
        closedir $dh;
    } # GET_FILES

    my ($code_key, $code_cmp);
  SET_CODE_CMP: {
        if (defined $args{key}) {
            $code_key = $args{key};
        }

        if (defined $args{by_code}) {
            $code_key //= sub { $_[0] };
            $code_cmp = $args{by_code};
            last;
        }

        if (defined $args{by_sortsub}) {
            require Sort::Sub;
            $code_key //= sub { $_[0]->{name} };
            $code_cmp = Sort::Sub::gen_sorter($args{by_sortsub}, $args{sortsub_args});
        }

        if (defined $args{by_field}) {
            if ($args{by_field} eq 'name') {
                $code_key //= sub { $_[0]->{name} };
                $code_cmp = sub { $_[0] cmp $_[1] };
            } elsif ($args{by_field} eq 'size') {
                $code_key //= sub { $_[0]->{size} };
                $code_cmp = sub { $_[0] <=> $_[1] };
            } elsif ($args{by_field} eq 'ctime') {
                $code_key //= sub { $_[0]->{ctime} };
                $code_cmp = sub { $_[0] <=> $_[1] };
            } elsif ($args{by_field} eq 'mtime') {
                $code_key //= sub { $_[0]->{mtime} };
                $code_cmp = sub { $_[0] <=> $_[1] };
            } else {
                return [400, "Invalid value in by_field: $args{by_field}"];
            }
            last;
        }

        return [400, "Please specify one of by_field/by_sortsub/by_code"];
    } # SET_CODE_CMP

    my (@ranks, @sorted_files);
  SORT: {
        require List::Rank;

        my @res = List::Rank::sortrankby(
            sub {
                ;
                my ($key1, $key2);
                {
                    local $_ = $a;
                    $key1 = $code_key->($a);
                }
                {
                    local $_ = $b;
                    $key2 = $code_key->($b);
                }
                $args{reverse} ? $code_cmp->($key2, $key1) : $code_cmp->($key1, $key2);
            },
            @files
        );
        while (my ($e1, $e2) = splice @res, 0, 2) {
            push @sorted_files, $e1;
            push @ranks, $e2;
        }
    } # SORT

  NUM_RESULTS: {
        last unless defined $args{num_results} && $args{num_results} > 0;
        last unless $args{num_results} < @sorted_files;
        splice @sorted_files, $args{num_results};
    }

  NUM_RANKS: {
        last unless defined $args{num_ranks} && $args{num_ranks} > 0;
        my @res;
        my $i = -1;
        while (1) {
            $i++;
            last if $i >= @sorted_files;
            my $rank = $ranks[$i];
            $rank =~ s/=\z//;
            last if $rank > $args{num_ranks};
            push @res, $sorted_files[$i];
        }
        @sorted_files = @res;
    }

    if ($args{detail}) {
        for (@sorted_files) { $_->{dir} = $dir }
    } else {
        @sorted_files = map { ($dir eq '.' ? '' : $dir eq '/' ? '/' : "$dir/") . $_->{name} } @sorted_files;
    }
    log_info "Sorted files: %s", \@sorted_files;

    [200, "OK", \@sorted_files];
}

# foremost
gen_modified_sub(
    die => 1,
    output_name => 'foremost',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    add_args => {
        %argspec_ignore_case,
    },
    summary => 'Return file(s) which are alphabetically the first',
    description => <<'MARKDOWN',

Some examples:

    # return foremost file in current directory
    % foremost -f

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_field => 'name',
            ($args{ignore_case} ? (key=>sub {lc $_[0]{name}}) : ()),
        );
    },
);

# hindmost
gen_modified_sub(
    die => 1,
    output_name => 'hindmost',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    add_args => {
        %argspec_ignore_case,
    },
    summary => 'Return file(s) which are alphabetically the last',
    description => <<'MARKDOWN',

Some examples:

    # return hindmost file in current directory
    % hindmost -f

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_field => 'name',
            ($args{ignore_case} ? (key=>sub {lc $_[0]{name}}) : ()),
            reverse => 1,
        );
    },
);

# largest
gen_modified_sub(
    die => 1,
    output_name => 'largest',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    summary => 'Return the largest file(s) in a directory',
    description => <<'MARKDOWN',

Some examples:

    # return largest file in current directory
    % largest -f

    # return largest file(s) in /some/dir (if there are multiple files with the
    # same size they will all be returned
    % largest -N1 -f /some/dir

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_field => 'size',
            reverse => 1,
        );
    },
);

# smallest
gen_modified_sub(
    die => 1,
    output_name => 'smallest',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    summary => 'Return the smallest file(s) in a directory',
    description => <<'MARKDOWN',

Some examples:

    # return smallest file in current directory
    % smallest -f

    # return smallest file(s) in /some/dir (if there are multiple files with the
    # same size they will all be returned
    % smallest -N1 -f /some/dir

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_field => 'size',
        );
    },
);

# newest
gen_modified_sub(
    die => 1,
    output_name => 'newest',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    summary => 'Return the newest file(s) in a directory',
    description => <<'MARKDOWN',

Suppose a new file is downloaded in `~/Downloads`, but you are not sure of its
name. You just want to move that file, which you are pretty sure is the newest
in the `Downloads` directory, somewhere else. So from the CLI in `~/Downloads`:

    % mv `newest -f` /somewhere/else

or, from `/somewhere/else`:

    % mv `newest -f ~/Downloads` .

If you want to see the filename on stderr as well:

    % mv `newest --verbose -f ~/Downloads` .

File is deemed as newest by its mtime.

Some examples:

    # return newest file in current directory
    % newest -f

    # return newest file(s) in /some/dir (if there are multiple files with the
    # same newest mtime) they will all be returned
    % newest -N1 -f /some/dir

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_field => 'mtime',
            reverse => 1,
        );
    },
);

# oldest
gen_modified_sub(
    die => 1,
    output_name => 'oldest',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    summary => 'Return the oldest file(s) in a directory',
    description => <<'MARKDOWN',

File is deemed as oldest by its mtime.

Some examples:

    # return oldest file in current directory
    % oldest -f

    # return oldest file(s) in /some/dir (if there are multiple files with the
    # same oldest mtime) they will all be returned
    % oldest -N1 -f /some/dir

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_field => 'mtime',
        );
    },
);

# longest_name
gen_modified_sub(
    die => 1,
    output_name => 'longest_name',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    summary => 'Return file(s) with the longest name in a directory',
    description => <<'MARKDOWN',

Some examples:

    # return file with the longest name in current directory
    % longest-name -f

    # return file(s) with the longest name in /some/dir. if there are multiple
    # files with the same length, they will all be returned.
    % longest-name -N1 -f /some/dir

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_code => sub { length($_[1]{name}) <=> length($_[0]{name}) },
        );
    },
);

# shortest_name
gen_modified_sub(
    die => 1,
    output_name => 'shortest_name',
    base_name => 'sort_files',
    remove_args => [keys %argspecs_sort],
    summary => 'Return file(s) with the shortest name in a directory',
    description => <<'MARKDOWN',

Some examples:

    # return file with the shortest name in current directory
    % shortest-name -f

    # return file(s) with the shortest name in /some/dir. if there are multiple
    # files with the same length, they will all be returned.
    % shortest-name -N1 -f /some/dir

MARKDOWN
    output_code => sub {
        my %args = @_;

        unless (defined $args{num_results} || defined $args{num_ranks}) {
            $args{num_results} = 1;
        }

        sort_files(
            %args,
            by_code => sub { length($_[0]{name}) <=> length($_[1]{name}) },
        );
    },
);

1;
# ABSTRACT: Utilities related to sorting files in a directory

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FileSortUtils - Utilities related to sorting files in a directory

=head1 VERSION

This document describes version 0.005 of App::FileSortUtils (from Perl distribution App-FileSortUtils), released on 2023-10-31.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item 1. L<foremost>

=item 2. L<hindmost>

=item 3. L<largest>

=item 4. L<longest-name>

=item 5. L<newest>

=item 6. L<oldest>

=item 7. L<shortest-name>

=item 8. L<smallest>

=item 9. L<sort-files>

=back

=head1 FUNCTIONS


=head2 foremost

Usage:

 foremost(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return file(s) which are alphabetically the first.

Some examples:

 # return foremost file in current directory
 % foremost -f

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 hindmost

Usage:

 hindmost(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return file(s) which are alphabetically the last.

Some examples:

 # return hindmost file in current directory
 % hindmost -f

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 largest

Usage:

 largest(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the largest file(s) in a directory.

Some examples:

 # return largest file in current directory
 % largest -f
 
 # return largest file(s) in /some/dir (if there are multiple files with the
 # same size they will all be returned
 % largest -N1 -f /some/dir

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 longest_name

Usage:

 longest_name(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return file(s) with the longest name in a directory.

Some examples:

 # return file with the longest name in current directory
 % longest-name -f
 
 # return file(s) with the longest name in /some/dir. if there are multiple
 # files with the same length, they will all be returned.
 % longest-name -N1 -f /some/dir

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 newest

Usage:

 newest(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the newest file(s) in a directory.

Suppose a new file is downloaded in C<~/Downloads>, but you are not sure of its
name. You just want to move that file, which you are pretty sure is the newest
in the C<Downloads> directory, somewhere else. So from the CLI in C<~/Downloads>:

 % mv C<newest -f> /somewhere/else

or, from C</somewhere/else>:

 % mv C<newest -f ~/Downloads> .

If you want to see the filename on stderr as well:

 % mv C<newest --verbose -f ~/Downloads> .

File is deemed as newest by its mtime.

Some examples:

 # return newest file in current directory
 % newest -f
 
 # return newest file(s) in /some/dir (if there are multiple files with the
 # same newest mtime) they will all be returned
 % newest -N1 -f /some/dir

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 oldest

Usage:

 oldest(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the oldest file(s) in a directory.

File is deemed as oldest by its mtime.

Some examples:

 # return oldest file in current directory
 % oldest -f
 
 # return oldest file(s) in /some/dir (if there are multiple files with the
 # same oldest mtime) they will all be returned
 % oldest -N1 -f /some/dir

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 shortest_name

Usage:

 shortest_name(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return file(s) with the shortest name in a directory.

Some examples:

 # return file with the shortest name in current directory
 % shortest-name -f
 
 # return file(s) with the shortest name in /some/dir. if there are multiple
 # files with the same length, they will all be returned.
 % shortest-name -N1 -f /some/dir

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 smallest

Usage:

 smallest(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the smallest file(s) in a directory.

Some examples:

 # return smallest file in current directory
 % smallest -f
 
 # return smallest file(s) in /some/dir (if there are multiple files with the
 # same size they will all be returned
 % smallest -N1 -f /some/dir

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<type> => I<str>

Only include files of certain type.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 sort_files

Usage:

 sort_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort files in a directory and display the result in a flexible way.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<by_code> => I<code_from_str>

Perl code to sort.

=item * B<by_field> => I<str>

Field name to sort against.

=item * B<by_sortsub> => I<str>

Sort::Sub routine name to sort.

=item * B<detail> => I<true>

(No description)

=item * B<dir> => I<dirname::default_curdir>

Directory to sort files of, defaults to current directory.

=item * B<key> => I<code_from_str>

Perl code to generate key to sort against.

If C<key> option is not specified, then: 1) if sorting is C<by_code> then the code
will receive files as records (hashes) with keys like C<name>, C<size>, etc; 2) if
sorting is C<by_field> then the associated field is used as key; 3) if sorting is
C<by_sortsub> then by default the C<name> field will be used as the key.

To select a field, use this:

 '$_->{FIELDNAME}'

for example:

 '$_->{size}'

Another example, to generate length of name as key:

 'length($_->{name})'

=item * B<num_ranks> => I<uint>

Number of ranks to return.

Difference between C<num_results> and C<num_ranks>: C<num_results> (C<-n> option)
specifies number of results regardless of ranks while C<num_ranks> (C<-N> option)
returns number of ranks. For example, if sorting is by reverse size and if
C<num_results> is set to 1 and there are 2 files with the same largest size then
only 1 of those files will be returned. With C<num_ranks> set to 1, both files
will be returned because are they both rank #1.

=item * B<num_results> => I<uint>

Number of results to return.

=item * B<reverse> => I<true>

Reverse order of sorting.

=item * B<sortsub_args> => I<hash>

Arguments to pass to Sort::Sub routine.

=item * B<type> => I<str>

Only include files of certain type.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-FileSortUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FileSortUtils>.

=head1 SEE ALSO

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FileSortUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
