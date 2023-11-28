package App::DownloadsDirUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';
use App::FileSortUtils;
use Perinci::Object;
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-16'; # DATE
our $DIST = 'App-DownloadsDirUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

$SPEC{list_downloads_dirs} = {
    v => 1.1,
    summary => 'List downloads directories',
    result_naked => 1,
};
sub list_downloads_dirs {
    require File::HomeDir;

    my @res;
    my $home;

    # ~/Downloads - firefox, ...
    {
        $home //= File::HomeDir->my_home;
        push @res, "$home/Downloads";
    }

    # mldonkey
    {
        $home //= File::HomeDir->my_home;
        push @res, "$home/.mldonkey/incoming/files";
    }

    @res = grep {-d} @res;

    wantarray ? @res : \@res;
}

for my $which (qw/foremost hindmost largest smallest newest oldest/) {
    my $res;

    $res = gen_modified_sub(
        summary => "Return the $which file(s) in the downloads directories",
        description => <<"MARKDOWN",

This is a thin wrapper for the <prog:$which> utility; the wrapper sets the
default for the directories to the downloads directories, as well as by default
excluding partial downloads (`*.part` files).

MARKDOWN
        output_name => __PACKAGE__ . "::${which}_download",
        base_name   => "App::FileSortUtils::$which",
        modify_args => {
            dirs => sub {
                my $arg_spec = shift;
                $arg_spec->{default} = scalar list_downloads_dirs();
            },
            exclude_filename_pattern => sub {
                my $arg_spec = shift;
                $arg_spec->{default} = '/\.part\z/';
            },
        },
        output_code => sub {
            no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
            my %args = @_;
            $args{dirs} //= scalar list_downloads_dirs();
            $args{exclude_filename_pattern} //= qr/\.part\z/;
            &{"App::FileSortUtils::$which"}(%args);
        },
    );
    die "Can't generate ${which}_download(): $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    $res = gen_modified_sub(
        summary => "Move the $which file(s) from the downloads directories to current directory",
        description => <<"MARKDOWN",

This is a thin wrapper for the <prog:${which}_download> utility; the wrapper
moves the files to current directory. It hopes to be a convenient helper to
organize your downloads.

MARKDOWN
        output_name => "mv_${which}_download_here",
        base_name   => "${which}_download",
        add_args => {
            to_dir => {
                schema => 'dirname*',
                default => '.',
            },
        },
        modify_meta => sub {
            my $meta = shift;
            $meta->{features} //= {};
            $meta->{features}{dry_run} = 1;
        },
        output_code => sub {
            no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
            require File::Copy::Recursive;

            my %args = @_;

            my $to_dir = delete($args{to_dir}) // '.';

            my $res = &{"${which}_download"}(%args);
            return $res unless $res->[0] == 200;
            return [404, "No $which file(s) returned"] unless @{ $res->[2] };

            my $envres = envresmulti();
            my $i = 0;
            for my $file (@{ $res->[2] }) {
                $i++;
                if ($args{-dry_run}) {
                    log_info "DRY-RUN: [%d/%d] Moving %s to %s ...", $i, scalar(@{ $res->[2] }), $file, $to_dir;
                    $envres->add_result(200, "OK (dry-run)", {item_id=>$file});
                } else {
                    log_info "[%d/%d] Moving %s to %s ...", $i, scalar(@{ $res->[2] }), $file, $to_dir;
                    my $ok = File::Copy::Recursive::rmove($file, $to_dir);
                    if ($ok) {
                        $envres->add_result(200, "OK", {item_id=>$file});
                    } else {
                        $envres->add_result(500, "Error: $!", {item_id=>$file});
                    }
                }
            }
            $envres->as_struct;
        },
    );
    die "Can't generate mv_${which}_download_here(): $res->[0] - $res->[1]"
        unless $res->[0] == 200;
} # $which

1;
# ABSTRACT: Utilities related to downloads directories

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DownloadsDirUtils - Utilities related to downloads directories

=head1 VERSION

This document describes version 0.003 of App::DownloadsDirUtils (from Perl distribution App-DownloadsDirUtils), released on 2023-11-16.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item 1. L<foremost-download>

=item 2. L<hindmost-download>

=item 3. L<largest-download>

=item 4. L<list-downloads-dirs>

=item 5. L<mv-foremost-download-here>

=item 6. L<mv-hindmost-download-here>

=item 7. L<mv-largest-download-here>

=item 8. L<mv-newest-download-here>

=item 9. L<mv-oldest-download-here>

=item 10. L<mv-smallest-download-here>

=item 11. L<newest-download>

=item 12. L<oldest-download>

=item 13. L<smallest-download>

=back

=head1 FUNCTIONS


=head2 foremost_download

Usage:

 foremost_download(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the foremost file(s) in the downloads directories.

This is a thin wrapper for the L<foremost> utility; the wrapper sets the
default for the directories to the downloads directories, as well as by default
excluding partial downloads (C<*.part> files).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

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



=head2 hindmost_download

Usage:

 hindmost_download(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the hindmost file(s) in the downloads directories.

This is a thin wrapper for the L<hindmost> utility; the wrapper sets the
default for the directories to the downloads directories, as well as by default
excluding partial downloads (C<*.part> files).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

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



=head2 largest_download

Usage:

 largest_download(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the largest file(s) in the downloads directories.

This is a thin wrapper for the L<largest> utility; the wrapper sets the
default for the directories to the downloads directories, as well as by default
excluding partial downloads (C<*.part> files).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

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



=head2 list_downloads_dirs

Usage:

 list_downloads_dirs() -> any

List downloads directories.

This function is not exported.

No arguments.

Return value:  (any)



=head2 mv_foremost_download_here

Usage:

 mv_foremost_download_here(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move the foremost file(s) from the downloads directories to current directory.

This is a thin wrapper for the L<foremost_download> utility; the wrapper
moves the files to current directory. It hopes to be a convenient helper to
organize your downloads.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

=item * B<to_dir> => I<dirname> (default: ".")

(No description)

=item * B<type> => I<str>

Only include files of certain type.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 mv_hindmost_download_here

Usage:

 mv_hindmost_download_here(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move the hindmost file(s) from the downloads directories to current directory.

This is a thin wrapper for the L<hindmost_download> utility; the wrapper
moves the files to current directory. It hopes to be a convenient helper to
organize your downloads.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<ignore_case> => I<bool>

(No description)

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

=item * B<to_dir> => I<dirname> (default: ".")

(No description)

=item * B<type> => I<str>

Only include files of certain type.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 mv_largest_download_here

Usage:

 mv_largest_download_here(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move the largest file(s) from the downloads directories to current directory.

This is a thin wrapper for the L<largest_download> utility; the wrapper
moves the files to current directory. It hopes to be a convenient helper to
organize your downloads.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

=item * B<to_dir> => I<dirname> (default: ".")

(No description)

=item * B<type> => I<str>

Only include files of certain type.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 mv_newest_download_here

Usage:

 mv_newest_download_here(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move the newest file(s) from the downloads directories to current directory.

This is a thin wrapper for the L<newest_download> utility; the wrapper
moves the files to current directory. It hopes to be a convenient helper to
organize your downloads.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

=item * B<to_dir> => I<dirname> (default: ".")

(No description)

=item * B<type> => I<str>

Only include files of certain type.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 mv_oldest_download_here

Usage:

 mv_oldest_download_here(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move the oldest file(s) from the downloads directories to current directory.

This is a thin wrapper for the L<oldest_download> utility; the wrapper
moves the files to current directory. It hopes to be a convenient helper to
organize your downloads.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

=item * B<to_dir> => I<dirname> (default: ".")

(No description)

=item * B<type> => I<str>

Only include files of certain type.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 mv_smallest_download_here

Usage:

 mv_smallest_download_here(%args) -> [$status_code, $reason, $payload, \%result_meta]

Move the smallest file(s) from the downloads directories to current directory.

This is a thin wrapper for the L<smallest_download> utility; the wrapper
moves the files to current directory. It hopes to be a convenient helper to
organize your downloads.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

=item * B<to_dir> => I<dirname> (default: ".")

(No description)

=item * B<type> => I<str>

Only include files of certain type.


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 newest_download

Usage:

 newest_download(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the newest file(s) in the downloads directories.

This is a thin wrapper for the L<newest> utility; the wrapper sets the
default for the directories to the downloads directories, as well as by default
excluding partial downloads (C<*.part> files).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

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



=head2 oldest_download

Usage:

 oldest_download(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the oldest file(s) in the downloads directories.

This is a thin wrapper for the L<oldest> utility; the wrapper sets the
default for the directories to the downloads directories, as well as by default
excluding partial downloads (C<*.part> files).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

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



=head2 smallest_download

Usage:

 smallest_download(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return the smallest file(s) in the downloads directories.

This is a thin wrapper for the L<smallest> utility; the wrapper sets the
default for the directories to the downloads directories, as well as by default
excluding partial downloads (C<*.part> files).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all> => I<true>

Do not ignore entries starting with .

=item * B<detail> => I<true>

(No description)

=item * B<dirs> => I<array[dirname]> (default: ["/home/u1/Downloads"])

Directory to sort files of, defaults to current directory.

=item * B<exclude_filename_pattern> => I<re_from_str> (default: "/\\.part\\z/")

Exclude filenames that match a regex pattern.

=item * B<include_filename_pattern> => I<re_from_str>

Only include filenames that match a regex pattern.

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

=item * B<recursive> => I<true>

Recurse into subdirectories.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-DownloadsDirUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DownloadsDirUtils>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DownloadsDirUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
