package App::BPOMUtils::RPO::Checker;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-16'; # DATE
our $DIST = 'App-BPOMUtils-RPO-Checker'; # DIST
our $VERSION = '0.006'; # VERSION

our @EXPORT_OK = qw(
                       bpom_rpo_check_label_files_design
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Various checker utilities to help with Processed Food Registration (RPO - Registrasi Pangan Olahan) at BPOM',
};

$SPEC{bpom_rpo_check_files} = {
    v => 1.1,
    summary => 'Check document files',
    description => <<'_',

By default will check all files in the current directory, recursively.

Here's what it checks:
- filename should not contain unsafe symbols
- file must not be larger than 5MB
- file must be readable

_
    args => {
        files => {
            schema => ['array*', of=>'filename', 'x.perl.default_value_rules' => [['Path::filenames']]],
            pos => 0,
            slurpy => 1,
        },
    },
};
sub bpom_rpo_check_files {
    my %args = @_;

    my $i = 0;
    my @errors;
    my @warnings;
    for my $file (@{ $args{files} }) {
        $i++;
        log_info "[%d/%d] Processing file %s ...", $i, scalar(@{ $args{files} }), $file;
        unless (-f $file) {
            push @errors, {file=>$file, message=>"File not found or not a regular file"};
            next;
        }

        if ($file =~ /\.[^.]+\./) {
            push @errors, {file=>$file, message=>"Filename contains multiple dots, currently uploadable but not viewable in ereg-rba"};
        }
        if ($file =~ /[^A-Za-z0-9_.-]/) {
            push @warnings, {file=>$file, message=>"Filename contains symbols, should be avoided to ensure viewable in ereg-rba"};
        }

        if (!-r($file)) {
            push @errors, {file=>$file, message=>"File cannot be read"};
            next;
        }

        my $filesize = -s $file;
        if ($filesize > 5*1024*1024) {
            push @errors, {file=>$file, message=>"File size too large (>5M)"};
        }
    }

    [200, "OK", [@errors, @warnings], {'cmdline.exit_code'=>@errors ? 1:0}];
}

$SPEC{bpom_rpo_check_files_label_design} = {
    v => 1.1,
    summary => 'Check label design files',
    description => <<'_',

By default will check all files in the current directory, recursively.

Here's what it checks:
- file must be in JPEG format and has name ending in /\.jpe?g$/i
- filename should not contain unsafe symbols
- file must not be larger than 5MB
- file must be readable
- image size must be smaller than 2300 x 2300 px
- (WARNING) image should not be smaller than 600 x 600 px

_
    args => {
        files => {
            schema => ['array*', of=>'filename', 'x.perl.default_value_rules' => [['Path::filenames']]],
            pos => 0,
            slurpy => 1,
        },
    },
};
sub bpom_rpo_check_files_label_design {
    require File::MimeInfo::Magic;
    require Image::Size;

    my %args = @_;

    my $i = 0;
    my @errors;
    my @warnings;
    for my $file (@{ $args{files} }) {
        $i++;
        log_info "[%d/%d] Processing file %s ...", $i, scalar(@{ $args{files} }), $file;
        unless (-f $file) {
            push @errors, {file=>$file, message=>"File not found or not a regular file"};
            next;
        }

        unless ($file =~ /\.jpe?g\z/i) {
            push @errors, {file=>$file, message=>"Filename does not end in .JPG or .JPEG"};
        }
        if ($file =~ /\.[^.]+\./) {
            push @errors, {file=>$file, message=>"Filename contains multiple dots, currently uploadable but not viewable in ereg-rba"};
        }
        if ($file =~ /[^A-Za-z0-9_.-]/) {
            push @warnings, {file=>$file, message=>"Filename contains symbols, should be avoided to ensure viewable in ereg-rba"};
        }

        if (!-r($file)) {
            push @errors, {file=>$file, message=>"File cannot be read"};
            next;
        }

        my $filesize = -s $file;
        if ($filesize < 100*1024) {
            push @warnings, {file=>$file, message=>"File size very small (<100k), perhaps increase quality?"};
        } elsif ($filesize > 5*1024*1024) {
            push @errors, {file=>$file, message=>"File size too large (>5M)"};
        }

        # because File::MimeInfo::Magic will report mime='inode/symlink' for symlink
        my $realfile = -l $file ? readlink($file) : $file;
        my $mime_type = File::MimeInfo::Magic::mimetype($realfile);
        unless ($mime_type eq 'image/jpeg') {
            push @errors, {file=>$file, message=>"File not in JPEG format (MIME=$mime_type)"};
        }

        my ($size_x, $size_y) = Image::Size::imgsize($file);
        if ($size_x >= 2300) { push @errors, {file=>$file, message=>"x too large ($size_x), xmax 2300 px"} }
        if ($size_y >= 2300) { push @errors, {file=>$file, message=>"y too large ($size_y), xmax 2300 px"} }
        if ($size_x < 600) { push @warnings, {file=>$file, message=>"WARNING: x too small ($size_x), should be 600+ px"} }
        if ($size_y < 600) { push @warnings, {file=>$file, message=>"WARNING: y too small ($size_y), should be 600+ px"} }
    }

    [200, "OK", [@errors, @warnings], {'cmdline.exit_code'=>@errors ? 1:0}];
}

1;
# ABSTRACT: Various checker utilities to help with Processed Food Registration (RPO - Registrasi Pangan Olahan) at BPOM

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils::RPO::Checker - Various checker utilities to help with Processed Food Registration (RPO - Registrasi Pangan Olahan) at BPOM

=head1 VERSION

This document describes version 0.006 of App::BPOMUtils::RPO::Checker (from Perl distribution App-BPOMUtils-RPO-Checker), released on 2023-02-16.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes CLI utilities related to helping with Processed Food
Registration (RPO - Registrasi Pangan Olahan).

=over

=item * L<bpom-rpo-check-files>

=item * L<bpom-rpo-check-files-label-design>

=back

=head1 FUNCTIONS


=head2 bpom_rpo_check_files

Usage:

 bpom_rpo_check_files(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check document files.

By default will check all files in the current directory, recursively.

Here's what it checks:
- filename should not contain unsafe symbols
- file must not be larger than 5MB
- file must be readable

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files> => I<array[filename]>

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



=head2 bpom_rpo_check_files_label_design

Usage:

 bpom_rpo_check_files_label_design(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check label design files.

By default will check all files in the current directory, recursively.

Here's what it checks:
- file must be in JPEG format and has name ending in /.jpe?g$/i
- filename should not contain unsafe symbols
- file must not be larger than 5MB
- file must be readable
- image size must be smaller than 2300 x 2300 px
- (WARNING) image should not be smaller than 600 x 600 px

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files> => I<array[filename]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils-RPO-Checker>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils-RPO-Checker>.

=head1 SEE ALSO

L<https://registrasipangan.pom.go.id>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils-RPO-Checker>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
