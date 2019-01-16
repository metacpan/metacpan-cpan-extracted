package App::BinPackUtils;

our $DATE = '2019-01-16'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

my %arg_bin_size = (
    bin_size => {
        schema => ['filesize*'],
        req => 1,
        cmdline_aliases => {s=>{}},
    },
);

my %argopt_bin_size_for_dvd = (
    bin_size => {
        schema => ['filesize*'],
        default => 4494*1024*1024,
        cmdline_aliases => {s=>{}},
    },
);

my %arg_files = (
    files => {
        schema => ['array*', of=>'filename*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

my %arg_move = (
    move => {
        summary => 'Actually move the files to the bins',
        schema => 'bool*',
    },
);

$SPEC{pack_bins} = {
    v => 1.1,
    summary => 'Pack items into bin',
    args => {
        %arg_bin_size,
        items => {
            schema => ['array*', of=>'str*'],
            summary => 'The items to be binned',
            description => <<'_',

Each item should be in this format: "label,size" (or an array with two elements,
the first one is the label and the second its size).

_
            req => 1,
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
    },
    examples => [
        {
            argv => ["-s", 100, "A,10", "B,50", "C,30", "D,70", "E,40", "F,40", "G,25"],
        },
    ],
};
sub pack_bins {
    require Algorithm::BinPack;

    my %args = @_;

    my $bp = Algorithm::BinPack->new(binsize => $args{bin_size});
    for my $item (@{ $args{items} }) {
        if (ref $item eq 'ARRAY') {
            $bp->add_item(label => $item->[0], size => $item->[1]);
        } else {
            my @item = split /\s*,\s*/, $item;
            $bp->add_item(label => $item[0], size => $item[1]);
        }
    }
    [200, "OK", [$bp->pack_bins]];
}

$SPEC{bin_files} = {
    v => 1.1,
    summary => 'Put files into bins',
    args => {
        %arg_bin_size,
        bin_prefix => {
            schema => 'filename*',
            default => 'bin',
        },
        %arg_files,
        %arg_move,
    },
    deps => {
        prog => 'du',
    },
};
sub bin_files {
    require String::ShellQuote;

    my %args = @_;
    my $bin_prefix = $args{bin_prefix} // "bin";

    my @items;
    for my $file (@{ $args{files} }) {
        return [404, "File '$file' does not exist"] unless -e $file;

        my $cmd = "du -sb ".String::ShellQuote::shell_quote($file);
        my $out = `$cmd`;
        my $size;
        if ($out =~ /\A(\d+)/) {
            $size = $1;
        } else {
            return [500, "Cannot find the size of '$file': $!"];
        }
        push @items, [$file, $size];
    }

    my $res = pack_bins(bin_size => $args{bin_size}, items => \@items);
    return $res unless $res->[0] == 200;

    # reformat as a single 2D table
    my @rows;
    my $bin_num = 0;
    my %bin_names;
    for my $bin (@{ $res->[2] }) {
        $bin_num++;
        for my $item (@{ $bin->{items} }) {
            my $bin_name = "$bin_prefix$bin_num";
            $bin_names{$bin_name}++;
            push @rows, {
                bin => $bin_name,
                file=>$item->{label},
                size=>$item->{size},
            };
        }
    }

    if ($args{move}) {
        # create all the directories for bins
        for my $bin_name (sort keys %bin_names) {
            return [412, "Directory $bin_name must not already exist"]
                if -d $bin_name;
            log_info "Creating directory $bin_name ...";
            mkdir $bin_name or return [500, "Can't create directory $bin_name: $!"];
        }
        # move files to bins
        for my $row (@rows) {
            log_info "Moving '$row->{file}' to $row->{bin} ...";
            rename($row->{file}, "$row->{bin}/$row->{file}") or do {
                log_warn "Can't move '$row->{file}' to $row->{bin}/: $!, skipped";
            };
        }
    }

    [200, "OK", \@rows];
}

$SPEC{bin_files_into_dvds} = {
    v => 1.1,
    summary => 'Put files into DVD bins',
    args => {
        %arg_files,
        %arg_move,
        %argopt_bin_size_for_dvd,
    },
    deps => {
        prog => 'du', # XXX indirectly
    },
};
sub bin_files_into_dvds {
    my %args = @_;

    bin_files(
        files      => $args{files},
        move       => $args{move},
        bin_prefix => "dvd",
        bin_size   => $args{bin_size} // 4493*1024*1024,
    );
}

1;
# ABSTRACT: Collection of CLI utilities related to packing items into bins

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BinPackUtils - Collection of CLI utilities related to packing items into bins

=head1 VERSION

This document describes version 0.002 of App::BinPackUtils (from Perl distribution App-BinPackUtils), released on 2019-01-16.

=head1 DESCRIPTION

This distribution provides the following command-line utilities:

=over

=item * L<bin-files>

=item * L<bin-files-into-dvds>

=item * L<pack-bins>

=back

Keywords: binpack, bin pack, packbin, pack bins, packing, binning.

=head1 FUNCTIONS


=head2 bin_files

Usage:

 bin_files(%args) -> [status, msg, payload, meta]

Put files into bins.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bin_prefix> => I<filename> (default: "bin")

=item * B<bin_size>* => I<filesize>

=item * B<files>* => I<array[filename]>

=item * B<move> => I<bool>

Actually move the files to the bins.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 bin_files_into_dvds

Usage:

 bin_files_into_dvds(%args) -> [status, msg, payload, meta]

Put files into DVD bins.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bin_size> => I<filesize> (default: 4712300544)

=item * B<files>* => I<array[filename]>

=item * B<move> => I<bool>

Actually move the files to the bins.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pack_bins

Usage:

 pack_bins(%args) -> [status, msg, payload, meta]

Pack items into bin.

Examples:

=over

=item * Example #1:

 pack_bins(
   items => ["A,10", "B,50", "C,30", "D,70", "E,40", "F,40", "G,25"],
   bin_size => 100
 );

Result:

 [
   {
     items => [{ label => "D", size => 70 }, { label => "C", size => 30 }],
     size  => 100,
   },
   {
     items => [
                { label => "B", size => 50 },
                { label => "E", size => 40 },
                { label => "A", size => 10 },
              ],
     size  => 100,
   },
   {
     items => [{ label => "F", size => 40 }, { label => "G", size => 25 }],
     size  => 65,
   },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bin_size>* => I<filesize>

=item * B<items>* => I<array[str]>

The items to be binned.

Each item should be in this format: "label,size" (or an array with two elements,
the first one is the label and the second its size).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-BinPackUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BinPackUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BinPackUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Algorithm::BinPack>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
