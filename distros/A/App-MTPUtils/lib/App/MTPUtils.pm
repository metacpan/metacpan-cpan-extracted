package App::MTPUtils;

our $DATE = '2015-11-07'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

our %SPEC;

my %arg_files = (
    files => {
        summary => 'Filenames/IDs/wildcards',
        'summary.alt.plurality.singular' => 'Filename/ID/wildcard',
        'x.name.is_plural' => 1,
        schema => ['array*', of=>'str*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
        element_completion => \&_complete_filename_or_id,
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to MTP (Media Transfer Protocol)',
};

my $out_name = "mtp-files.out";

my $err_no_mtp_files_out = [412, "No $out_name present, please create it first using 'mtp-files > $out_name'"];

sub _parse_mtp_files_output {
    (-f $out_name) or return undef;
    open my($fh), "<", $out_name or die "Can't open '$out_name': $!";
    my %files_by_id; # key: id, value: {name=>..., size=>..., pid=>...}
    my %files_by_name; # key: name, value: [id, ...]
    my $cur_file;
    my $code_add_file = sub {
        my $file = shift or return;
        $files_by_id{$file->{id}} = $file;
        $files_by_name{$file->{name}} //= [];
        push @{ $files_by_name{$file->{name}} }, $file->{id};
    };
    while (defined(my $line = <$fh>)) {
        if ($line =~ /^File ID: (\d+)/) {
            $code_add_file->($cur_file);
            $cur_file = {id=>$1};
            next;
        }
        if (defined $cur_file) {
            if ($line =~ /^\s+Filename: (.+)/) {
                $cur_file->{name} = $1;
            } elsif ($line =~ /^\s+File size (\d+)/) {
                $cur_file->{size} = $1;
            } elsif ($line =~ /^\s+Parent ID: (\d+)/) {
                $cur_file->{pid} = $1;
            }
        }
    }
    $code_add_file->($cur_file);
    #use DD; dd \%files_by_id; dd \%files_by_name;
    return [\%files_by_id, \%files_by_name];
}

sub _complete_filename_or_id {
    require Complete::Util;
    my %args = @_;

    my $parse_res = _parse_mtp_files_output() or return undef;

    my ($files_by_id, $files_by_name) = @$parse_res;

    Complete::Util::complete_array_elem(
        %args,
        array => [keys(%$files_by_id), keys(%$files_by_name)],
    );
}

$SPEC{list_files} = {
    v => 1.1,
    summary => 'List files contained in mtp-files.out',
    description => <<'_',

This routine will present information in `mtp-files.out` in a more readable way,
like the Unix `ls` command.

To use this routine, you must already run `mtp-files` and save its output in
`mtp-files.out` file, e.g.:

    % mtp-files > mtp-files.out

_
    args => {
        queries => {
            summary => 'Filenames/wildcards',
            'summary.alt.plurality.singular' => 'Filename/wildcard',
            'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
            element_completion => \&_complete_filename_or_id,
        },
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_files {
    require Regexp::Wildcards;
    require String::Wildcard::Bash;

    my %args = @_;
    my $qq = $args{queries} // [];

    my $parse_res = _parse_mtp_files_output()
        or return $err_no_mtp_files_out;
    my ($files_by_id, $files_by_name) = @$parse_res;

    # convert wildcards to regexes
    $qq = [@$qq];
    for (@$qq) {
        next unless String::Wildcard::Bash::contains_wildcard($_);
        my $re = Regexp::Wildcards->new(type=>'unix')->convert($_);
        $re = qr/\A($re)\z/;
        $_ = $re;
    }

    my @res;
    my %resmeta;

    if ($args{detail}) {
        $resmeta{'table.fields'} = [qw/name id pid size/];
    }

    # XXX report error on non-matching query
    my %seen_ids;
    for my $name (sort keys %$files_by_name) {
        my $ids;
        if (@$qq) {
            for my $q (@$qq) {
                if (ref($q) eq 'Regexp') {
                    if ($name =~ $q) { $ids = $files_by_name->{$name}; last }
                } elsif ($q =~ /\A\d+\z/) {
                    if ($files_by_id->{$q} && !$seen_ids{$q}) {
                        $ids = [$q];
                    }
                } else {
                    if ($name eq $q) { $ids = $files_by_name->{$name}; last }
                }
            }
        } else {
            $ids = $files_by_name->{$name};
        }
        next unless $ids;
        for my $id (@$ids) {
            next if $seen_ids{$id}++;
            my $rec = $files_by_id->{$id};
            if ($args{detail}) {
                push @res, $rec;
            } else {
                push @res, $rec->{name};
            }
        }
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{get_files} = {
    v => 1.1,
    summary => 'Get multiple files from MTP (wrapper for mtp-getfile)',
    description => <<'_',

This routine is a thin wrapper for `mtp-file` command from `mtp-tools`.

To use this routine, you must already run `mtp-files` and save its output in
`mtp-files.out` file, e.g.:

    % mtp-files > mtp-files.out

This file is used for tab completion as well as getting filename/ID when only
one is specified. This makes using `mtp-getfile` less painful.

_
    args => {
        %arg_files,
        overwrite => {
            schema => 'bool',
            cmdline_aliases => {O=>{}},
        },
    },
    deps => {
        prog => 'mtp-getfile',
    },
};
sub get_files {
    require IPC::System::Options;

    my %args = @_;

    my $res = list_files(queries=>$args{files}, detail=>1);
    return $res unless $res->[0] == 200;

    return [412, "No matching files to get"] unless @{$res->[2]};

    my $num_files = @{ $res->[2] };
    for my $i (1..$num_files) {
        my $file = $res->[2][$i-1];
        $log->infof("[%d/%d] Getting file '%s' ...",
                    $i, $num_files, $file->{name});
        if ((-f $file->{name}) && !$args{overwrite}) {
            $log->warnf("Skipped file '%s' (%d) (already exists)",
                        $file->{name}, $file->{id});
            next;
        }
        IPC::System::Options::system(
            {log=>1, shell=>0},
            "mtp-getfile",
            $file->{id},
            $file->{name},
        );
    }

    [200, "OK"];
}

$SPEC{delete_files} = {
    v => 1.1,
    summary => 'Delete multiple files from MTP (wrapper for mtp-delfile)',
    description => <<'_',

This routine is a thin wrapper for `mtp-delfile` command from `mtp-tools`.

To use this routine, you must already run `mtp-files` and save its output in
`mtp-files.out` file, e.g.:

    % mtp-files > mtp-files.out

This file is used for tab completion as well as getting filename/ID when only
one is specified. This makes using `mtp-delfile` less painful.

_
    args => {
        %arg_files,
    },
    deps => {
        prog => 'mtp-delfile',
    },
};
sub delete_files {
    require IPC::System::Options;

    my %args = @_;

    my $res = list_files(queries=>$args{files}, detail=>1);
    return $res unless $res->[0] == 200;

    return [412, "No matching files to delete"] unless @{$res->[2]};

    my $num_files = @{ $res->[2] };
    for my $i (1..$num_files) {
        my $file = $res->[2][$i-1];
        $log->infof("[%d/%d] deleting file '%s' ...",
                    $i, $num_files, $file->{name});
        IPC::System::Options::system(
            {log=>1, shell=>0},
            "mtp-delfile", "-n", $file->{id},
        );
    }

    [200, "OK"];
}

1;
# ABSTRACT: CLI utilities related to MTP (Media Transfer Protocol)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MTPUtils - CLI utilities related to MTP (Media Transfer Protocol)

=head1 VERSION

This document describes version 0.03 of App::MTPUtils (from Perl distribution App-MTPUtils), released on 2015-11-07.

=head1 SYNOPSIS

This distribution includes the following CLI utilities:

=over

=back

Currently these utilities are just some wrappers/helpers for the C<mtp-*> CLI
utilities distributed in C<mtp-tools>.

=head1 SEE ALSO

mtp-tools from libmtp, L<http://libmtp.sourceforge.net>

=head1 FUNCTIONS


=head2 delete_files(%args) -> [status, msg, result, meta]

Delete multiple files from MTP (wrapper for mtp-delfile).

This routine is a thin wrapper for C<mtp-delfile> command from C<mtp-tools>.

To use this routine, you must already run C<mtp-files> and save its output in
C<mtp-files.out> file, e.g.:

 % mtp-files > mtp-files.out

This file is used for tab completion as well as getting filename/ID when only
one is specified. This makes using C<mtp-delfile> less painful.

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

Filenames/IDs/wildcards.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_files(%args) -> [status, msg, result, meta]

Get multiple files from MTP (wrapper for mtp-getfile).

This routine is a thin wrapper for C<mtp-file> command from C<mtp-tools>.

To use this routine, you must already run C<mtp-files> and save its output in
C<mtp-files.out> file, e.g.:

 % mtp-files > mtp-files.out

This file is used for tab completion as well as getting filename/ID when only
one is specified. This makes using C<mtp-getfile> less painful.

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[str]>

Filenames/IDs/wildcards.

=item * B<overwrite> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_files(%args) -> [status, msg, result, meta]

List files contained in mtp-files.out.

This routine will present information in C<mtp-files.out> in a more readable way,
like the Unix C<ls> command.

To use this routine, you must already run C<mtp-files> and save its output in
C<mtp-files.out> file, e.g.:

 % mtp-files > mtp-files.out

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<queries> => I<array[str]>

Filenames/wildcards.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-MTPUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MTPUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MTPUtils>

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
