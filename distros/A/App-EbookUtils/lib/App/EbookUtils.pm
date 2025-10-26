package App::EbookUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;
use IPC::System::Options -log=>1, 'system';
use Perinci::Object;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-10-26'; # DATE
our $DIST = 'App-EbookUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

my %argspec0_files__epub = (
    files => {
        schema => ['array*', of=>'filename*', min_len=>1,
                   #uniq=>1, # not yet implemented by Data::Sah
               ],
        req => 1,
        pos => 0,
        slurpy => 1,
        'x.element_completion' => [filename => {filter => sub { /\.epub$/i }}],
    },
);

my %argspec0_files__cbz = (
    files => {
        schema => ['array*', of=>'filename*', min_len=>1,
                   #uniq=>1, # not yet implemented by Data::Sah
               ],
        req => 1,
        pos => 0,
        slurpy => 1,
        'x.element_completion' => [filename => {filter => sub { /\.cbz$/i }}],
    },
);

my %argspec0_files__cbr = (
    files => {
        schema => ['array*', of=>'filename*', min_len=>1,
                   #uniq=>1, # not yet implemented by Data::Sah
               ],
        req => 1,
        pos => 0,
        slurpy => 1,
        'x.element_completion' => [filename => {filter => sub { /\.cbr$/i }}],
    },
);

our %argspecopt_overwrite = (
    overwrite => {
        schema => 'bool*',
        cmdline_aliases => {O=>{}},
    },
);

$SPEC{convert_epub_to_pdf} = {
    v => 1.1,
    summary => 'Convert epub file to PDF',
    description => <<'MARKDOWN',

This utility is a simple wrapper to `ebook-convert`. It allows setting output
filenames (`foo.epub.pdf`) so you don't have to specify them manually. It also
allows processing multiple files in a single invocation

MARKDOWN
    args => {
        %argspec0_files__epub,
        %argspecopt_overwrite,
    },
    deps => {
        prog => 'ebook-convert',
    },
};
sub convert_epub_to_pdf {
    my %args = @_;

    my $envres = envresmulti();

    my $i = 0;
    for my $input_file (@{ $args{files} }) {
        log_info "[%d/%d] Processing file %s ...", ++$i, scalar(@{ $args{files} }), $input_file;
        $input_file =~ /(.+)\.(\w+)\z/ or do {
            $envres->add_result(412, "Please supply input file with extension in its name (e.g. foo.epub instead of foo)", {item_id=>$input_file});
            next;
        };
        my ($name, $ext) = ($1, $2);
        $ext =~ /\Aepub\z/i or do {
            $envres->add_result(412, "Input file '$input_file' does not have .epub extension", {item_id=>$input_file});
            next;
        };

        my $output_file = "$input_file.pdf";

        if (-e $output_file) {
            if ($args{overwrite}) {
                log_info "Unlinking existing PDF file %s ...", $output_file;
                unlink $output_file;
            } else {
                $envres->add_result(412, "Output file '$output_file' already exists, not overwriting (use --overwrite (-O) to overwrite)", {item_id=>$input_file});
                next;
            }
        }

        system("ebook-convert", $input_file, $output_file);
        my $exit_code = $? < 0 ? $? : $? >> 8;
        if ($exit_code) {
            $envres->add_result(500, "ebook-convert didn't return successfully, exit code=$exit_code", {item_id=>$input_file});
        } else {
            $envres->add_result(200, "OK", {item_id=>$input_file});
        }
    } # for $input_file

    $envres->as_struct;
}

sub _convert_cbx_to_pdf_single {
    my ($which, $input_file, $output_file) = @_;

    log_info("Creating temporary directory ...");
    require File::Temp;
    my $tempdir = File::Temp::tempdir(CLEANUP => log_is_debug() ? 0:1);
    log_debug("Temporary directory is $tempdir");

    require Cwd;
    my $abs_input_file = Cwd::abs_path($input_file)
        or return [500, "Can't get absolute path of input file '$input_file'"];
    my $abs_output_file = Cwd::abs_path($output_file)
        or return [500, "Can't get absolute path of output file '$output_file'"];

    log_info("Extracting $abs_input_file ...");
    local $CWD = $tempdir;
    if ($which eq 'cbz') {
        system("unzip", $abs_input_file);
    } elsif ($which eq 'cbr') {
        system("unrar", "e", $abs_input_file);
    } else {
        return [412, "Unknown extension '$which': must be cbz/cbr"];
    }
    my $exit_code = $? < 0 ? $? : $? >> 8;
    return [500, "Can't unzip $abs_input_file ($exit_code): $!"]
        if $exit_code;

    log_info("Converting images to PDFs ...");
    my @input_img_files = glob "*";
    my @input_pdf_files;
    my $num_files = @input_img_files;
    my $i = 0;
    for my $file (@input_img_files) {
        $i++;
        log_info "[#%d/%d] Processing %s ...", $i, $num_files, $file;
        unless (-f $file) {
            log_warn "Found a non-regular file inside $input_file: $file, skipped";
            next;
        }
        system("convert", $file, "$file.pdf");
        my $exit_code = $? < 0 ? $? : $? >> 8;
        if ($exit_code) {
            log_error "Can't convert $file to $file.pdf ($exit_code): $!, skipped";
            next;
        }
        push @input_pdf_files, "$file.pdf";
    }

    log_info "Combining all PDFs into a single one ...";
    system "pdftk", @input_pdf_files, "cat", "output", $abs_output_file;
    $exit_code = $? < 0 ? $? : $? >> 8;
    return [500, "Can't combine PDFs into a single one ($exit_code): $!"]
        if $exit_code;

    [200];
}

$SPEC{convert_cbz_to_pdf} = {
    v => 1.1,
    summary => 'Convert cbz file to PDF',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %argspec0_files__cbz,
        %argspecopt_overwrite,
    },
    deps => {
        all => [
            {prog => 'unzip'},
            {prog => 'pdftk'},
            {prog => 'convert'},
        ],
    },
};
sub convert_cbz_to_pdf {
    my %args = @_;

    my $envres = envresmulti();

    my $i = 0;
    for my $input_file (@{ $args{files} }) {
        log_info "[%d/%d] Processing file %s ...", ++$i, scalar(@{ $args{files} }), $input_file;
        $input_file =~ /(.+)\.(\w+)\z/ or do {
            $envres->add_result(412, "Please supply input file with extension in its name (e.g. foo.cbz instead of foo)", {item_id=>$input_file});
            next;
        };
        my ($name, $ext) = ($1, $2);
        $ext =~ /\Acbz\z/i or do {
            $envres->add_result(412, "Input file '$input_file' does not have .cbz extension", {item_id=>$input_file});
            next;
        };

        my $output_file = "$input_file.pdf";

        if (-e $output_file) {
            if ($args{overwrite}) {
                log_info "Unlinking existing PDF file %s ...", $output_file;
                unlink $output_file;
            } else {
                $envres->add_result(412, "Output file '$output_file' already exists, not overwriting (use --overwrite (-O) to overwrite)", {item_id=>$input_file});
                next;
            }
        }

        my $convert_res = _convert_cbx_to_pdf_single("cbz", $input_file, $output_file);
        if ($convert_res->[0] != 200) {
            $envres->add_result($convert_res->[0], "Can't convert return successfully, $convert_res->[0] - $convert_res->[1]", {item_id=>$input_file});
        } else {
            $envres->add_result(200, "OK", {item_id=>$input_file});
        }
    } # for $input_file

    $envres->as_struct;
}

$SPEC{convert_cbr_to_pdf} = {
    v => 1.1,
    summary => 'Convert cbr file to PDF',
    description => <<'MARKDOWN',

MARKDOWN
    args => {
        %argspec0_files__cbr,
        %argspecopt_overwrite,
    },
    deps => {
        all => [
            {prog => 'unrar'},
            {prog => 'pdftk'},
            {prog => 'convert'},
        ],
    },
};
sub convert_cbr_to_pdf {
    my %args = @_;

    my $envres = envresmulti();

    my $i = 0;
    for my $input_file (@{ $args{files} }) {
        log_info "[%d/%d] Processing file %s ...", ++$i, scalar(@{ $args{files} }), $input_file;
        $input_file =~ /(.+)\.(\w+)\z/ or do {
            $envres->add_result(412, "Please supply input file with extension in its name (e.g. foo.cbr instead of foo)", {item_id=>$input_file});
            next;
        };
        my ($name, $ext) = ($1, $2);
        $ext =~ /\Acbr\z/i or do {
            $envres->add_result(412, "Input file '$input_file' does not have .cbr extension", {item_id=>$input_file});
            next;
        };

        my $output_file = "$input_file.pdf";

        if (-e $output_file) {
            if ($args{overwrite}) {
                log_info "Unlinking existing PDF file %s ...", $output_file;
                unlink $output_file;
            } else {
                $envres->add_result(412, "Output file '$output_file' already exists, not overwriting (use --overwrite (-O) to overwrite)", {item_id=>$input_file});
                next;
            }
        }

        my $convert_res = _convert_cbx_to_pdf_single("cbr", $input_file, $output_file);
        if ($convert_res->[0] != 200) {
            $envres->add_result($convert_res->[0], "Can't convert return successfully, $convert_res->[0] - $convert_res->[1]", {item_id=>$input_file});
        } else {
            $envres->add_result(200, "OK", {item_id=>$input_file});
        }
    } # for $input_file

    $envres->as_struct;
}

1;
# ABSTRACT: Command-line utilities related to ebooks

__END__

=pod

=encoding UTF-8

=head1 NAME

App::EbookUtils - Command-line utilities related to ebooks

=head1 VERSION

This document describes version 0.003 of App::EbookUtils (from Perl distribution App-EbookUtils), released on 2025-10-26.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution provides tha following command-line utilities related to
ebooks:

=over

=item * L<cbr2pdf>

=item * L<cbz2pdf>

=item * L<convert-cbr-to-pdf>

=item * L<convert-cbz-to-pdf>

=item * L<convert-epub-to-pdf>

=item * L<epub2pdf>

=back

=head1 FUNCTIONS


=head2 convert_cbr_to_pdf

Usage:

 convert_cbr_to_pdf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert cbr file to PDF.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>

(No description)

=item * B<overwrite> => I<bool>

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



=head2 convert_cbz_to_pdf

Usage:

 convert_cbz_to_pdf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert cbz file to PDF.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>

(No description)

=item * B<overwrite> => I<bool>

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



=head2 convert_epub_to_pdf

Usage:

 convert_epub_to_pdf(%args) -> [$status_code, $reason, $payload, \%result_meta]

Convert epub file to PDF.

This utility is a simple wrapper to C<ebook-convert>. It allows setting output
filenames (C<foo.epub.pdf>) so you don't have to specify them manually. It also
allows processing multiple files in a single invocation

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>

(No description)

=item * B<overwrite> => I<bool>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-EbookUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-EbookUtils>.

=head1 SEE ALSO

L<App::PDFUtils>

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-EbookUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
