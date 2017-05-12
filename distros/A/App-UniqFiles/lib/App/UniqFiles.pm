package App::UniqFiles;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.11'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG qw($log);

use Digest::MD5;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(uniq_files);

our %SPEC;

$SPEC{uniq_files} = {
    v => 1.1,
    summary => 'Report or omit duplicate file contents',
    description => <<'_',

Given a list of filenames, will check each file size and content for duplicate
content. Interface is a bit like the `uniq` Unix command-line program.

_
    args    => {
        files => {
            schema => ['array*' => {of=>'str*'}],
            req    => 1,
            pos    => 0,
            greedy => 1,
        },
        report_unique => {
            schema => [bool => {default=>1}],
            summary => 'Whether to return unique items',
            cmdline_aliases => {
                u => {
                    summary => 'Alias for --report-unique --report-duplicate=0',
                    code => sub {
                        my $args = shift;
                        $args->{report_unique}    = 1;
                        $args->{report_duplicate} = 0;
                    },
                },
                d => {
                    summary =>
                        'Alias for --noreport-unique --report-duplicate=1',
                    code => sub {
                        my $args = shift;
                        $args->{report_unique}    = 0;
                        $args->{report_duplicate} = 1;
                    },
                },
            },
        },
        report_duplicate => {
            schema => [int => {default=>2}],
            summary => 'Whether to return duplicate items',
            description => <<'_',

Can be set to either 0, 1, 2.

If set to 2 (the default), will only return the first of duplicate items. For
example: file1 contains text 'a', file2 'b', file3 'a'. Only file1 will be
returned because file2 is unique and file3 contains 'a' (already represented by
file1).

If set to 1, will return all the the duplicate items. From the above example:
file1 and file3 will be returned.

If set to 0, duplicate items will not be returned.

_
            cmdline_aliases => {
            },
        },
        check_content => {
            schema => [bool => {default=>1}],
            summary => "Whether to check file content ",
            description => <<'_',

If set to 0, uniqueness will be determined solely from file size. This can be
quicker but might generate a false positive when two files of the same size are
deemed as duplicate even though their content are different.

_
        },
        count => {
            schema => [bool => {default=>0}],
            summary => "Whether to return each file content's ".
                "number of occurence",
            description => <<'_',

1 means the file content is only encountered once (unique), 2 means there is one
duplicate, and so on.

_
        },
    },
    examples => [
        {
            summary   => 'List all files which do no have duplicate contents',
            src       => 'uniq-files *',
            src_plang => 'bash',
        },
        {
            summary   => 'List all files which have duplicate contents',
            src       => 'uniq-files -d *',
            src_plang => 'bash',
        },
        {
            summary   => 'List number of occurences of contents for each file',
            src       => 'uniq-files -c *',
            src_plang => 'bash',
        },
    ],
};
sub uniq_files {
    my %args = @_;

    my $files = $args{files};
    return [400, "Please specify files"] if !$files || !@$files;
    my $report_unique    = $args{report_unique}    // 1;
    my $report_duplicate = $args{report_duplicate} // 2;
    my $check_content    = $args{check_content}    // 1;
    my $count            = $args{count}            // 0;

    # get sizes of all files
    my %size_counts; # key = size, value = number of files having that size
    my %file_sizes; # key = filename, value = file size, for caching stat()
    for my $f (@$files) {
        my @st = stat $f;
        unless (@st) {
            $log->error("Can't stat file `$f`: $!, skipped");
            next;
        }
        $size_counts{$st[7]}++;
        $file_sizes{$f} = $st[7];
    }

    # calculate digest for all files having non-unique sizes
    my %digest_counts; # key = digest, value = num of files having that digest
    my %digest_files; # key = digest, value = [file, ...]
    my %file_digests; # key = filename, value = file digest
    for my $f (@$files) {
        next unless defined $file_sizes{$f};
        next if $size_counts{ $file_sizes{$f} } == 1;
        my $digest;
        if ($check_content) {
            my $fh;
            unless (open $fh, "<", $f) {
                $log->error("Can't open file `$f`: $!, skipped");
                next;
            }
            my $ctx = Digest::MD5->new;
            $ctx->addfile($fh);
            $digest = $ctx->hexdigest;
        } else {
            $digest = "";
        }
        $digest_counts{$digest}++;
        $digest_files{$digest} //= [];
        push @{$digest_files{$digest}}, $f;
        $file_digests{$f} = $digest;
    }

    my %file_counts; # key = file name, value = num of files having file content
    for my $f (@$files) {
        next unless defined $file_sizes{$f};
        if (!defined($file_digests{$f})) {
            $file_counts{$f} = 1;
        } else {
            $file_counts{$f} = $digest_counts{ $file_digests{$f} };
        }
    }

    if ($count) {
        return [200, "OK", \%file_counts];
    } else {
        #$log->trace("report_duplicate=$report_duplicate");
        my @files;
        for (sort keys %file_counts) {
            if ($file_counts{$_} == 1) {
                #$log->trace("unique file `$_`");
                push @files, $_ if $report_unique;
            } else {
                #$log->trace("duplicate file `$_`");
                if ($report_duplicate == 1) {
                    push @files, $_;
                } elsif ($report_duplicate == 2) {
                    my $digest = $file_digests{$_};
                    push @files, $_ if $_ eq $digest_files{$digest}[0];
                }
            }
        }
        return [200, "OK", \@files];
    }
}

1;
# ABSTRACT: Report or omit duplicate file contents

__END__

=pod

=encoding UTF-8

=head1 NAME

App::UniqFiles - Report or omit duplicate file contents

=head1 VERSION

This document describes version 0.11 of App::UniqFiles (from Perl distribution App-UniqFiles), released on 2015-09-03.

=head1 SYNOPSIS

 # See uniq-files script

=head1 NOTES

Warning: cannot properly handle symlinks or special files (socket, pipe,
device), so don't feed them.

=head1 FUNCTIONS


=head2 uniq_files(%args) -> [status, msg, result, meta]

Report or omit duplicate file contents.

Examples:

 uniq_files();


List all files which do no have duplicate contents.


 uniq_files();


List all files which have duplicate contents.


 uniq_files();


List number of occurences of contents for each file.


Given a list of filenames, will check each file size and content for duplicate
content. Interface is a bit like the C<uniq> Unix command-line program.

Arguments ('*' denotes required arguments):

=over 4

=item * B<check_content> => I<bool> (default: 1)

Whether to check file content .

If set to 0, uniqueness will be determined solely from file size. This can be
quicker but might generate a false positive when two files of the same size are
deemed as duplicate even though their content are different.

=item * B<count> => I<bool> (default: 0)

Whether to return each file content's number of occurence.

1 means the file content is only encountered once (unique), 2 means there is one
duplicate, and so on.

=item * B<files>* => I<array[str]>

=item * B<report_duplicate> => I<int> (default: 2)

Whether to return duplicate items.

Can be set to either 0, 1, 2.

If set to 2 (the default), will only return the first of duplicate items. For
example: file1 contains text 'a', file2 'b', file3 'a'. Only file1 will be
returned because file2 is unique and file3 contains 'a' (already represented by
file1).

If set to 1, will return all the the duplicate items. From the above example:
file1 and file3 will be returned.

If set to 0, duplicate items will not be returned.

=item * B<report_unique> => I<bool> (default: 1)

Whether to return unique items.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-UniqFiles>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-UniqFiles>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-UniqFiles>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
