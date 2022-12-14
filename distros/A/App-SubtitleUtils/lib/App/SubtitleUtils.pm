package App::SubtitleUtils;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-11-23'; # DATE
our $DIST = 'App-SubtitleUtils'; # DIST
our $VERSION = '0.012'; # VERSION

our @EXPORT_OK = qw(
                       srtparse
                       srtcheck
                       srtdump
                       srtcombinetext
               );

our %SPEC;

my $secs_re = qr/[+-]?\d+(?:\.\d*)?/;
my $hms_re = qr/\d\d?:\d\d?:\d\d?(?:,\d{1,3})?/;
my $hms_re_catch = qr/(\d\d?):(\d\d?):(\d\d?)(?:,(\d{1,3}))?/;

sub _hms2secs { no warnings 'uninitialized'; local $_=shift; /^$hms_re_catch$/ or return; $1*3600+$2*60+$3+$4*0.001 }
# support negative
#sub _hms2secs { no warnings 'uninitialized'; local $_=shift; /^$hms_re_catch$/ or return; "${1}1" * ($2*3600+$3*60+$4+$5*0.001) }

sub _secs2hms { no warnings 'uninitialized'; local $_=shift; /^$secs_re$/ or return "00:00:00,000"; my $ms=1000*($_-int($_)); $_=int($_); my $s=$_%60; $_-=$s; $_/=60; my $m=$_%60; $_-=$m; $_/=60; sprintf "%02d:%02d:%02d,%03d",$_,$m,$s,$ms }

$SPEC{srtparse} = {
    v => 1.1,
    summary => 'Parse SRT and return data structure',
    args => {
        filename => {
            schema => 'filename*',
            'x.completion' => [filename => {file_ext_filter=>qr/\.srt$/i}],
            pos => 0,
        },
        string => {
            schema => 'str*',
        },
    },
    args_rels => {
        req_one => [qw/filename string/],
    },
};
sub srtparse {
    my %args = @_;

    my $parsed = {
        entries => [],
        warnings => [],
    };

    my $string = $args{string};
    unless (defined $string) {
        open my $fh, "<", $args{filename} or return [500, "Can't open file $args{filename}: $!"];
        local $/;
        $string = <$fh>;
        close $fh;
        $parsed->{_filename} = $args{filename};
    }

    my $para = "";
    my $linenum = 0;
    my @lines = split /^/m, $string;
    if ($lines[-1] =~ /\S/) {
        # add extra blank line
        push @{ $parsed->{_warnings} }, "No extra blank line at the end";
        push @lines, "\n";
    }
    for my $line (@lines) {
        $linenum++;
	if ($line =~ /\S/) {
            $line =~ s/\015//g;
            $para .= $line;
	} elsif ($para =~ /\S/) {
            my ($no, $hms1, $hms2, $text) = $para =~ /(\d+)\n($hms_re) ---?> ($hms_re)(?:\s*X1:\d+\s+X2:\d+\s+Y1:\d+\s+Y2:\d+\s*)?\n(.+)/s or
                return [500, "Invalid entry in line $linenum: $para"];
            push @{$parsed->{entries}}, {
                no => $no,
                time1 => $hms1,
                time2 => $hms2,
                _time1_as_secs => _hms2secs($hms1),
                _time2_as_secs => _hms2secs($hms2),
                text => $text,
            };
            $para = "";
	} else {
            $para = "";
	}
    }

    $parsed->{_num_entries} = @{ $parsed->{entries} };

    [200, "OK", $parsed];
}

$SPEC{srtcheck} = {
    v => 1.1,
    summary => 'Check the properness of SRT file',
    args => {
        filename => {
            schema => 'filename*',
            'x.completion' => [filename => {file_ext_filter=>qr/\.srt$/i}],
            req => 1,
            pos => 0,
        },
    },
};
sub srtcheck {
    my %args = @_;

    my $res = srtparse(filename => $args{filename});
    return $res unless $res->[0] == 200;
    my $parsed = $res->[2];

    return [400, "Parse has warnings: ".join(", ", @{ $parsed->{_warnings} })]
        if @{ $parsed->{_warnings} };

    for my $i (0 .. $#{ $parsed->{entries} }) {
        my $entry = $parsed->{entries}[$i];
        my $num = $entry->{no};
        return [400, "Number should be ".($i+1).", not $num"]
            if $num != $i+1;
    }
    [200, "OK"];
}

$SPEC{srtdump} = {
    v => 1.1,
    args => {
        parsed => {
            schema => 'hash*',
            req => 1,
            pos => 0,
        },
    },
};
sub srtdump {
    my %args = @_;

    my $parsed = $args{parsed};

    my $text = 0;
    for my $entry (@{ $parsed->{entries} }) {
        $text .= "$entry->{no}\n$entry->{time1} --> $entry->{time2}\n$entry->{text}\n";
    }

    [200, "OK", $text];
}

$SPEC{srtcombinetext} = {
    v => 1.1,
    summary => 'Combine the text of two or more subtitle files (e.g. for different languages) into one',
    description => <<'_',

All the subtitle files must contain the same number of entries, with each entry
containing the exact timestamps. The default is just to concatenate the text of
each entry together, but you can customize each text using the `--eval` option.

_
    args => {
        filenames => {
            schema => ['array*', of=>'filename*', min_len=>2],
            'x.element_completion' => [filename => {file_ext_filter=>qr/\.srt$/i}],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
        eval => {
            summary => 'Perl code to evaluate on every text',
            schema => 'str*', # XXX or code
            cmdline_aliases => {e=>{}},
            description => <<'_',

This code will be evaluated for every text of each entry of each SRT, in the
`main` package. `$_` will be set to the text, `$main::entry` to the entry hash,
`$main::idx` to the index of the files (starts at 0).

The code is expected to modify `$_`.

_
        },
    },
    examples => [
        {
            summary => 'Display English and French subtitles together (1)',
            description => <<'_',

The English text is shown at the top, then a blank line (`<i></i>`), followed by
the French text in italics.

_
            src_plang => 'bash',
            src => q|[[prog]] azur-et-asmar.en.srt azur-et-asmar.fr.srt -e 'if ($main::idx) { chomp; $_ = "<i></i>\n<i>$_</i>\n" }'|,
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Display English and French subtitles together (2)',
            description => <<'_',

Like the previous examaple, we show the English text at the top, then a blank
line (`<i></i>`), followed by the French text in italics. This time we use a
provided wrapper.

_
            src_plang => 'bash',
            src => q|srtcombine2text azur-et-asmar.en.srt azur-et-asmar.fr.srt|,
            test => 0,
            'x.doc.show_result' => 0,

        },
    ],
};
sub srtcombinetext {
    my %args = @_;

    my @parsed;
    my $filenum = 0;
    my $num_entries;
    for my $filename (@{ $args{filenames} }) {
        $filenum++;
        my $res = srtparse(filename => $filename);
        return [500, "Can't parse SRT #$filenum '$filename': $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        my $parsed = $res->[2];
        if ($filenum == 1) {
            $num_entries = @{ $parsed->{entries} };
        } elsif (@{ $parsed->{entries} } != $num_entries) {
            return [412, "SRT #$filenum '$filename' has different number of entries (".scalar(@{ $parsed->{entries} })." vs $num_entries)"];
        }
        push @parsed, $parsed;
    }

    my $code;
    my $merged = {entries=>[]};
    for my $i (0 .. $num_entries-1) {
        my ($time1, $time2, $merged_text);
        $merged_text = "";
        for my $j (0..$#parsed) {
            if ($j == 0) {
                $time1 = $parsed[$j]{entries}[$i]{time1};
                $time2 = $parsed[$j]{entries}[$i]{time2};
            } else {
                return [412, "SRT #".($j+1)." '$args{filename}[$j]' entry ".($i+1).": different timestamp"]
                    if
                    $parsed[$j]{entries}[$i]{time1} ne $time1 ||
                    $parsed[$j]{entries}[$i]{time2} ne $time2;
            }
            {
                local $_ = $parsed[$j]{entries}[$i]{text};
                if (defined $args{eval}) {
                    if (!$code) {
                        $code = eval "package main; no strict; no warnings; sub { $args{eval} }"; ## no critic: BuiltinFunctions::ProhibitStringyEval
                        return [400, "Eval code does not compile: $@"] if $@;
                    }
                    no warnings 'once';
                    local $main::entry = $parsed[$j]{entries}[$i];
                    local $main::idx = $j;
                    $code->();
                }
                $merged_text .= $_;
            }
        }
        push @{ $merged->{entries} }, {
            no => $i+1,
            time1 => $time1,
            time2 => $time2,
            _time1_as_secs => _hms2secs($time1),
            _time2_as_secs => _hms2secs($time2),
            text => $merged_text,
        };
    }

    srtdump(parsed => $merged);
}

$SPEC{srtcombine2text} = {
    v => 1.1,
    summary => 'Combine the text of two subtitle files (e.g. for different languages) into one',
    description => <<'_',

This is a thin wrapper for <prog:srtcombinetext>, for convenience. This:

    % srtcombine2text file1.srt file2.srt

is equivalent to:

    % srtcombinetext file1.srt file2.srt -e 'if ($main::idx) { chomp; $_ = "<i></i>\n<i>$_</i>\n" }'

For more customization, use *srtcombinetext* directly.

_
    args => {
        filename1 => {
            schema => 'filename*',
            'x.completion' => [filename => {file_ext_filter=>qr/\.srt$/i}],
            req => 1,
            pos => 0,
        },
        filename2 => {
            schema => 'filename*',
            'x.completion' => [filename => {file_ext_filter=>qr/\.srt$/i}],
            req => 1,
            pos => 0,
        },
    },
    examples => [
        {
            summary => 'Display English and French subtitles together',
            src_plang => 'bash',
            src => q|[[prog]] azur-et-asmar.en.srt azur-et-asmar.fr.srt|,
            test => 0,
            'x.doc.show_result' => 0,

        },
    ],
};
sub srtcombine2text {
    my %args = @_;
    my $filename1 = delete $args{filename1};
    my $filename2 = delete $args{filename2};
    srtcombinetext(
        filenames => [$filename1, $filename2],
        eval => q|if ($main::idx) { chomp; $_ = "<i></i>\n<i>$_</i>\n" }|,
    );
}

1;
# ABSTRACT: Utilities related to video subtitles

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SubtitleUtils - Utilities related to video subtitles

=head1 VERSION

This document describes version 0.012 of App::SubtitleUtils (from Perl distribution App-SubtitleUtils), released on 2022-11-23.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<srtadjust>

=item * L<srtcalc>

=item * L<srtcheck>

=item * L<srtcombine2text>

=item * L<srtcombinetext>

=item * L<srtparse>

=item * L<srtrenumber>

=item * L<srtscale>

=item * L<srtshift>

=item * L<srtsplit>

=item * L<subscale>

=item * L<subshift>

=item * L<vtt2srt>

=back

=head1 FUNCTIONS


=head2 srtcheck

Usage:

 srtcheck(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check the properness of SRT file.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 srtcombine2text

Usage:

 srtcombine2text(%args) -> [$status_code, $reason, $payload, \%result_meta]

Combine the text of two subtitle files (e.g. for different languages) into one.

This is a thin wrapper for L<srtcombinetext>, for convenience. This:

 % srtcombine2text file1.srt file2.srt

is equivalent to:

 % srtcombinetext file1.srt file2.srt -e 'if ($main::idx) { chomp; $_ = "<i></i>\n<i>$_</i>\n" }'

For more customization, use I<srtcombinetext> directly.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename1>* => I<filename>

(No description)

=item * B<filename2>* => I<filename>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 srtcombinetext

Usage:

 srtcombinetext(%args) -> [$status_code, $reason, $payload, \%result_meta]

Combine the text of two or more subtitle files (e.g. for different languages) into one.

All the subtitle files must contain the same number of entries, with each entry
containing the exact timestamps. The default is just to concatenate the text of
each entry together, but you can customize each text using the C<--eval> option.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<eval> => I<str>

Perl code to evaluate on every text.

This code will be evaluated for every text of each entry of each SRT, in the
C<main> package. C<$_> will be set to the text, C<$main::entry> to the entry hash,
C<$main::idx> to the index of the files (starts at 0).

The code is expected to modify C<$_>.

=item * B<filenames>* => I<array[filename]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 srtdump

Usage:

 srtdump(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<parsed>* => I<hash>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 srtparse

Usage:

 srtparse(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse SRT and return data structure.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<filename>

(No description)

=item * B<string> => I<str>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-SubtitleUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SubtitleUtils>.

=head1 SEE ALSO

=head1 HISTORY

Most of them are scripts I first wrote in 2003 and first packaged as CPAN
distribution in late 2020. They need to be rewritten to properly use
L<Getopt::Long> etc; someday.

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

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SubtitleUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
