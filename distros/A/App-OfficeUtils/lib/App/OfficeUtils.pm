package App::OfficeUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-26'; # DATE
our $DIST = 'App-OfficeUtils'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our %args_libreoffice = (
    libreoffice_path => {
        schema => 'filename*',
        tags => ['category:libreoffice'],
    },
);

our %arg0_input_file = (
    input_file => {
        summary => 'Path to input file',
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

our %arg1_output_file = (
    output_file => {
        summary => 'Path to output file',
        schema => 'filename*',
        pos => 1,
        description => <<'_',

If not specified, will output to stdout.

_
    },
);

our %arg1_output_file_or_dir = (
    output_file_or_dir => {
        summary => 'Path to output file or directory',
        schema => 'pathname*',
        req => 1,
        pos => 1,
        description => <<'_',

If not specified, will output to stdout.

_
    },
);

our %argopt_overwrite = (
    overwrite => {
        schema => 'bool*',
        cmdline_aliases => {O=>{}},
    },
);

$SPEC{officewp2txt} = {
    v => 1.1,
    summary => 'Convert Office word-processor format file (.doc, .docx, .odt, etc) to .txt',
    description => <<'_',

This utility uses one of the following backends:

* LibreOffice

_
    args => {
        %arg0_input_file,
        %arg1_output_file,
        %argopt_overwrite,
        %args_libreoffice,
        return_output_file => {
            summary => 'Return the path of output file instead',
            schema => 'bool*',
            description => <<'_',

This is useful when you do not specify an output file but do not want to show
the converted document to stdout, but instead want to get the path to a
temporary output file.

_
        },
        fmt => {
            summary => 'Run Unix fmt over the txt output',
            schema => 'bool*',
        },
    },
};
sub officewp2txt {
    my %args = @_;

    require File::Copy;
    require File::Temp;
    require File::Which;
    require IPC::System::Options;

  USE_LIBREOFFICE: {
        my $libreoffice_path = $args{libreoffice_path} //
            File::Which::which("libreoffice") //
              File::Which::which("soffice");
        unless (defined $libreoffice_path) {
            log_debug "libreoffice is not in PATH, skipped trying to use libreoffice";
            last;
        }

        my $input_file = $args{input_file};
        $input_file =~ /(.+)\.(\w+)\z/ or return [412, "Please supply input file with extension in its name (e.g. foo.doc instead of foo)"];
        my ($name, $ext) = ($1, $2);
        $ext =~ /\Ate?xt\z/i and return [304, "Input file '$input_file' is already text"];
        my $output_file = $args{output_file};

        if (defined $output_file && -e $output_file && !$args{overwrite}) {
            return [412, "Output file '$output_file' already exists, not overwriting (use --overwrite (-O) to overwrite)"];
        }

        my $tempdir = File::Temp::tempdir(CLEANUP => !$args{return_output_file});
        my ($temp_fh, $temp_file) = File::Temp::tempfile(undef, SUFFIX => ".$ext", DIR => $tempdir);
        (my $temp_out_file = $temp_file) =~ s/\.\w+\z/.txt/;
        File::Copy::copy($input_file, $temp_file) or do {
            return [500, "Can't copy '$input_file' to '$temp_file': $!"];
        };
        # XXX check that $temp_file/.doc/.txt doesn't exist yet
        IPC::System::Options::system(
            {die=>1, log=>1},
            $libreoffice_path, "--headless", "--convert-to", "txt:Text (encoded):UTF8", $temp_file, "--outdir", $tempdir);

      FMT: {
            last unless $args{fmt};
            return [412, "fmt is not in PATH"] unless File::Which::which("fmt");
            my $stdout;
            IPC::System::Options::system(
                {die=>1, log=>1, capture_stdout=>\$stdout},
                "fmt", $temp_out_file,
            );
            open my $fh, ">" , "$temp_out_file.fmt" or return [500, "Can't open '$temp_out_file.fmt': $!"];
            print $fh $stdout;
            close $fh;
            $temp_out_file .= ".fmt";
        }

        if (defined $output_file || $args{return_output_file}) {
            if (defined $output_file) {
                File::Copy::copy($temp_out_file, $output_file) or do {
                    return [500, "Can't copy '$temp_out_file' to '$output_file': $!"];
                };
            } else {
                $output_file = $temp_out_file;
            }
            return [200, "OK", $args{return_output_file} ? $output_file : undef];
        } else {
            open my $fh, "<", $temp_out_file or return [500, "Can't open '$temp_out_file': $!"];
            local $/;
            my $content = <$fh>;
            close $fh;
            return [200, "OK", $content, {"cmdline.skip_format"=>1}];
        }
    }

    [412, "No backend available"];
}

$SPEC{officess2csv} = {
    v => 1.1,
    summary => 'Convert Office spreadsheet format file (.ods, .xls, .xlsx) to one or more CSV files',
    description => <<'_',

This utility uses <pm:Spreadsheet::XLSX> to extract cell values of worksheets
and put them in one or more CSV file(s). If spreadsheet format is not .xlsx
(e.g. .ods or .xls), it will be converted to .xlsx first using Libreoffice
(headless mode).

You can select one or more worksheets to export. If unspecified, the default is
the first worksheet only. If you specify more than one worksheets, you need to
specify output *directory* instead of *output* file.

_
    args => {
        %arg0_input_file,
        %arg1_output_file_or_dir,
        %argopt_overwrite,
        %args_libreoffice,
        # XXX option to merge all csvs as a single file?
        worksheets => {
            summary => 'Select which worksheet(s) to convert',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'worksheet',
            schema => ['array*', of=>'str*'],
            cmdline_aliases => {s=>{}},
        },
        all_worksheets => {
            summary => 'Convert all worksheets in the workbook',
            schema => 'true*',
            cmdline_aliases => {a=>{}},
        },
        always_dir => {
            summary => 'Assume output_file_or_dir is a directory even though there is only one worksheet',
            schema => 'bool*',
        },
    },
};
sub officess2csv {
    my %args = @_;

    my $input_file = $args{input_file} or return [400, "Please specify input_file"];
    my $output_file_or_dir = $args{output_file_or_dir} or return [400, "Please specify output_file_or_dir"];

    if (-e $output_file_or_dir && !$args{overwrite}) {
        return [412, "Output file/dir '$output_file_or_dir' already exists, not overwriting unless you specify --overwrite"];
    }

  CONVERT_TO_XLSX: {
        last if $input_file =~ /\.xlsx\z/i;
        require File::Copy;
        require File::Temp;
        require File::Which;
        require IPC::System::Options;

        my $libreoffice_path = $args{libreoffice_path} //
            File::Which::which("libreoffice") //
              File::Which::which("soffice");
        unless (defined $libreoffice_path) {
            log_debug "libreoffice is not in PATH, skipped trying to use libreoffice";
            last;
        }

        $input_file =~ /(.+)\.(\w+)\z/ or return [412, "Please supply input file with extension in its name (e.g. foo.doc instead of foo)"];
        my ($name, $ext) = ($1, $2);

        my $tempdir = File::Temp::tempdir(CLEANUP => !$ENV{DEBUG});
        my ($temp_fh, $temp_file) = File::Temp::tempfile(undef, SUFFIX => ".$ext", DIR => $tempdir);
        (my $temp_out_file = $temp_file) =~ s/\.\w+\z/.xlsx/;
        File::Copy::copy($input_file, $temp_file) or do {
            return [500, "Can't copy '$input_file' to '$temp_file': $!"];
        };
        log_debug "Converting $input_file -> $temp_out_file ...";
        IPC::System::Options::system(
            {die=>1, log=>1},
            $libreoffice_path, "--headless", "--convert-to", "xlsx", $temp_file, "--outdir", $tempdir);

        $input_file = $temp_out_file;
        log_trace "input xlsx file=$input_file";
    }

    #require Text::Iconv;
    #my $converter = Text::Iconv->new("utf-8", "windows-1251");
    my $converter;

    require Spreadsheet::XLSX;
    my $xlsx = Spreadsheet::XLSX->new($input_file, $converter);
    my @all_worksheets = map { $_->{Name} } @{ $xlsx->{Worksheet} };
    log_debug "Available worksheets in this workbook: %s", \@all_worksheets;
    my @worksheets;
    if ($args{all_worksheets}) {
        @worksheets = @all_worksheets;
        log_debug "Will be exporting all worksheet(s): %s", \@worksheets;
    } elsif ($args{worksheets}) {
        @worksheets = @{ $args{worksheets} };
        log_debug "Will be exporting these worksheet(s): %s", \@worksheets;
    } else {
        log_debug "Will only be exporting the first worksheet ($all_worksheets[0])";
        @worksheets = ($all_worksheets[0]);
    }

    my @output_files;
    if (@worksheets == 1 && !$args{always_dir}) {
        @output_files = ($output_file_or_dir);
    } else {
        unless (-d $output_file_or_dir) {
            log_debug "Creating directory $output_file_or_dir ...";
            mkdir $output_file_or_dir or do {
                return [500, "Can't mkdir $output_file_or_dir: $!, bailing out"];;
            };
        }
        for (@worksheets) {
            # XXX convert to safe filename
            push @output_files, "$output_file_or_dir/$_.csv";
        }
    }

    require Text::CSV_XS;
    my $csv = Text::CSV_XS->new({binary=>1});
  WRITE_WORKSHEET: {
        for my $i (0..$#worksheets) {
            my $worksheet = $worksheets[$i];
            my $output_file = $output_files[$i];
            log_debug "Outputting worksheet $worksheet to $output_file ...";

            my $sheet;
            for my $sheet0 (@{ $xlsx->{Worksheet} }) {
                if ($sheet0->{Name} eq $worksheet) {
                    $sheet = $sheet0; last;
                }
            }
            unless ($sheet) {
                log_error "Cannot find worksheet $worksheet, skipped";
                next WRITE_WORKSHEET;
            }

            open my $fh, ">", $output_file or do {
                log_error "Cannot open output file '$output_file': $!, skipped";
                next WRITE_WORKSHEET;
            };

            $sheet -> {MaxRow} ||= $sheet -> {MinRow};
            for my $row ($sheet->{MinRow} .. $sheet->{MaxRow}) {
                $sheet->{MaxCol} ||= $sheet->{MinCol};
                my @row;
                foreach my $col ($sheet->{MinCol} ..  $sheet->{MaxCol}) {
                    my $cell = $sheet->{Cells}[$row][$col];
                    push @row, $cell ? $cell->{Val} : undef;
                }
                $csv->combine(@row);
                print $fh $csv->string, "\n";
            }
        }
    }

    [200, "OK"];
}

1;
# ABSTRACT: Utilities related to Office suite files (.doc, .docx, .odt, .xls, .xlsx, .ods, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OfficeUtils - Utilities related to Office suite files (.doc, .docx, .odt, .xls, .xlsx, .ods, etc)

=head1 VERSION

This document describes version 0.004 of App::OfficeUtils (from Perl distribution App-OfficeUtils), released on 2020-10-26.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<doc2txt>

=item * L<xls2csv>

=back

=head1 FUNCTIONS


=head2 officess2csv

Usage:

 officess2csv(%args) -> [status, msg, payload, meta]

Convert Office spreadsheet format file (.ods, .xls, .xlsx) to one or more CSV files.

This utility uses L<Spreadsheet::XLSX> to extract cell values of worksheets
and put them in one or more CSV file(s). If spreadsheet format is not .xlsx
(e.g. .ods or .xls), it will be converted to .xlsx first using Libreoffice
(headless mode).

You can select one or more worksheets to export. If unspecified, the default is
the first worksheet only. If you specify more than one worksheets, you need to
specify output I<directory> instead of I<output> file.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<all_worksheets> => I<true>

Convert all worksheets in the workbook.

=item * B<always_dir> => I<bool>

Assume output_file_or_dir is a directory even though there is only one worksheet.

=item * B<input_file>* => I<filename>

Path to input file.

=item * B<libreoffice_path> => I<filename>

=item * B<output_file_or_dir>* => I<pathname>

Path to output file or directory.

If not specified, will output to stdout.

=item * B<overwrite> => I<bool>

=item * B<worksheets> => I<array[str]>

Select which worksheet(s) to convert.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 officewp2txt

Usage:

 officewp2txt(%args) -> [status, msg, payload, meta]

Convert Office word-processor format file (.doc, .docx, .odt, etc) to .txt.

This utility uses one of the following backends:

=over

=item * LibreOffice

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fmt> => I<bool>

Run Unix fmt over the txt output.

=item * B<input_file>* => I<filename>

Path to input file.

=item * B<libreoffice_path> => I<filename>

=item * B<output_file> => I<filename>

Path to output file.

If not specified, will output to stdout.

=item * B<overwrite> => I<bool>

=item * B<return_output_file> => I<bool>

Return the path of output file instead.

This is useful when you do not specify an output file but do not want to show
the converted document to stdout, but instead want to get the path to a
temporary output file.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 DEBUG

If set to true, will not clean up temporary directories.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-OfficeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OfficeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OfficeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::MSOfficeUtils>, L<App::LibreOfficeUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
