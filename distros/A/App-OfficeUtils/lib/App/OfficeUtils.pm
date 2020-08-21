package App::OfficeUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-21'; # DATE
our $DIST = 'App-OfficeUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our %arg0_input_file = (
    input_file => {
        summary => 'Path to input file',
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

our %arg0_output_file = (
    output_file => {
        summary => 'Path to output file',
        schema => 'filename*',
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
        %arg0_output_file,
        %argopt_overwrite,
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
        unless (File::Which::which("libreoffice")) {
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

        my $tempdir = File::Temp::tempdir(CLEANUP => 1);
        my ($temp_fh, $temp_file) = File::Temp::tempfile(undef, SUFFIX => ".$ext", DIR => $tempdir);
        (my $temp_out_file = $temp_file) =~ s/\.\w+\z/.txt/;
        File::Copy::copy($input_file, $temp_file) or do {
            return [500, "Can't copy '$input_file' to '$temp_file': $!"];
        };
        # XXX check that $temp_file/.doc/.txt doesn't exist yet
        IPC::System::Options::system(
            {die=>1, log=>1},
            "libreoffice", "--headless", "--convert-to", "txt:Text (encoded):UTF8", $temp_file, "--outdir", $tempdir);

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

        if (defined $output_file) {
            File::Copy::copy($temp_out_file, $output_file) or do {
                return [500, "Can't copy '$temp_out_file' to '$output_file': $!"];
            };
            return [200, "OK"];
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

1;
# ABSTRACT: Utilities related to Office suite files (.doc, .docx, .odt, .xls, .xlsx, .ods, etc)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OfficeUtils - Utilities related to Office suite files (.doc, .docx, .odt, .xls, .xlsx, .ods, etc)

=head1 VERSION

This document describes version 0.001 of App::OfficeUtils (from Perl distribution App-OfficeUtils), released on 2020-08-21.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<doc2txt>

=back

=head1 FUNCTIONS


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

=item * B<output_file> => I<filename>

Path to output file.

If not specified, will output to stdout.

=item * B<overwrite> => I<bool>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-OfficeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-OfficeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-OfficeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
