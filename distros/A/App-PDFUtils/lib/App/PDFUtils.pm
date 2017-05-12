package App::PDFUtils;

our $DATE = '2017-04-22'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

use Perinci::Object;

our %SPEC;

my %arg_files = (
    files => {
        schema => ['array*', of=>'filename*', min_len=>1,
                   #uniq=>1, # not yet implemented by Data::Sah
               ],
        req => 1,
        pos => 0,
        greedy => 1,
        'x.completion' => [filename => {filter => sub { /\.pdf$/i }}],
    },
);

$SPEC{add_pdf_password} = {
    v => 1.1,
    summary => 'Password-protect PDF files',
    description => <<'_',

This program is a wrapper for <prog:qpdf> to password-protect PDF files
(in-place). This is the counterpart for <prog:remove-pdf-password>.

_
    args => {
        %arg_files,
        password => {
            schema => ['str*', min_len=>1],
            req => 1,
        },
        backup => {
            summary => 'Whether to backup the original file to ORIG~',
            schema => 'bool*',
            default => 1,
        },
        # XXX key_length (see qpdf, but when 256 can't be opened by evince)
        # XXX other options (see qpdf)
    },
    deps => {
        prog => 'qpdf',
    },
    links => [
        {url => 'prog:remove-pdf-password'},
    ],
};
sub add_pdf_password {
    #require File::Temp;
    require IPC::System::Options;
    #require Proc::ChildError;
    #require Path::Tiny;

    my %args = @_;

    my $envres = envresmulti();

  FILE:
    for my $f (@{ $args{files} }) {
        unless (-f $f) {
            $envres->add_result(404, "File not found", {item_id=>$f});
            next FILE;
        }
        # XXX test that tempfile doesn't yet exist. but actually we can't avoid
        # race condition because qpdf is another process
        my $tempf = "$f.tmp" . int(rand()*900_000 + 100_000);

        my $decrypted;
        my ($stdout, $stderr);
        IPC::System::Options::system(
            {log => 1, capture_stdout => \$stdout, capture_stderr => \$stderr},
            "qpdf", "--encrypt", $args{password}, $args{password}, 128, "--", $f, $tempf);
        my $err = $?;# ? Proc::ChildError::explain_child_error() : '';
        if ($err && $stderr =~ /: invalid password$/) {
            $envres->add_result(412, "File already encrypted", {item_id=>$f});
            next FILE;
        } elsif ($err) {
            $stderr =~ s/\R//g;
            $envres->add_result(500, $stderr, {item_id=>$f});
            next FILE;
        }

      BACKUP:
        {
            last unless $args{backup};
            unless (rename $f, "$f~") {
                warn "Can't backup original '$f' to '$f~': $!, skipped backup\n";
                last;
            };
        }
        unless (rename $tempf, $f) {
            $envres->add_result(500, "Can't rename $tempf to $f: $!", {item_id=>$f});
            next FILE;
        }
        $envres->add_result(200, "OK", {item_id=>$f});
    }

    $envres->as_struct;
}

$SPEC{remove_pdf_password} = {
    v => 1.1,
    summary => 'Remove password from PDF files',
    description => <<'_',

This program is a wrapper for <prog:qpdf> to remove passwords from PDF files
(in-place).

The motivation for this program is the increasing occurence of financial
institutions sending financial statements or documents in the format of
password-protected PDF file. This is annoying when we want to archive the file
or use it in an organization because we have to remember different passwords for
different financial institutions and re-enter the password everytime we want to
use the file. (The banks could've sent the PDF in a password-protected .zip, or
use PGP-encrypted email, but I digress.)

You can provide the passwords to be tried in a configuration file,
`~/remove-pdf-password.conf`, e.g.:

 passwords = pass1
 passwords = pass2
 passwords = pass3

or:

 passwords = ["pass1", "pass2", "pass3"]

_
    args => {
        %arg_files,
        passwords => {
            schema => ['array*', of=>['str*', min_len=>1], min_len=>1],
        },
        backup => {
            summary => 'Whether to backup the original file to ORIG~',
            schema => 'bool*',
            default => 1,
        },
    },
    deps => {
        prog => 'qpdf',
    },
    links => [
        {url => 'prog:add-pdf-password'},
    ],
};
sub remove_pdf_password {
    #require File::Temp;
    require IPC::System::Options;
    #require Proc::ChildError;
    #require Path::Tiny;

    my %args = @_;

    my $envres = envresmulti();

  FILE:
    for my $f (@{ $args{files} }) {
        unless (-f $f) {
            $envres->add_result(404, "File not found", {item_id=>$f});
            next FILE;
        }
        # XXX test that tempfile doesn't yet exist. but actually we can't avoid
        # race condition because qpdf is another process
        my $tempf = "$f.tmp" . int(rand()*900_000 + 100_000);

        my $decrypted;
      PASSWORD:
        for my $p (@{ $args{passwords} }) {
            my ($stdout, $stderr);
            IPC::System::Options::system(
                {log => 1, capture_stdout => \$stdout, capture_stderr => \$stderr},
                "qpdf", "--password=$p", "--decrypt", $f, $tempf);
            my $err = $?;# ? Proc::ChildError::explain_child_error() : '';
            if ($err && $stderr =~ /: invalid password$/) {
                #$log->tracef("D1");
                unlink $tempf; # just to make sure
                next PASSWORD;
            } elsif ($err) {
                #$log->tracef("D2");
                $stderr =~ s/\R//g;
                $envres->add_result(500, $stderr, {item_id=>$f});
                next FILE;
            }
            last;
        }
        unless (-f $tempf) {
            $envres->add_result(412, "No passwords can be successfully used on $f", {item_id=>$f});
            next FILE;
        }

      BACKUP:
        {
            last unless $args{backup};
            unless (rename $f, "$f~") {
                warn "Can't backup original '$f' to '$f~': $!, skipped backup\n";
                last;
            };
        }
        unless (rename $tempf, $f) {
            $envres->add_result(500, "Can't rename $tempf to $f: $!", {item_id=>$f});
            next FILE;
        }
        $envres->add_result(200, "OK", {item_id=>$f});
    }

    $envres->as_struct;
}

1;
# ABSTRACT: Command-line utilities related to PDF files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDFUtils - Command-line utilities related to PDF files

=head1 VERSION

This document describes version 0.002 of App::PDFUtils (from Perl distribution App-PDFUtils), released on 2017-04-22.

=head1 SYNOPSIS

This distribution provides tha following command-line utilities related to PDF
files:

=over

=item * L<add-pdf-password>

=item * L<remove-pdf-password>

=back

=head1 FUNCTIONS


=head2 add_pdf_password

Usage:

 add_pdf_password(%args) -> [status, msg, result, meta]

Password-protect PDF files.

This program is a wrapper for L<qpdf> to password-protect PDF files
(in-place). This is the counterpart for L<remove-pdf-password>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 1)

Whether to backup the original file to ORIG~.

=item * B<files>* => I<array[filename]>

=item * B<password>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 remove_pdf_password

Usage:

 remove_pdf_password(%args) -> [status, msg, result, meta]

Remove password from PDF files.

This program is a wrapper for L<qpdf> to remove passwords from PDF files
(in-place).

The motivation for this program is the increasing occurence of financial
institutions sending financial statements or documents in the format of
password-protected PDF file. This is annoying when we want to archive the file
or use it in an organization because we have to remember different passwords for
different financial institutions and re-enter the password everytime we want to
use the file. (The banks could've sent the PDF in a password-protected .zip, or
use PGP-encrypted email, but I digress.)

You can provide the passwords to be tried in a configuration file,
C<~/remove-pdf-password.conf>, e.g.:

 passwords = pass1
 passwords = pass2
 passwords = pass3

or:

 passwords = ["pass1", "pass2", "pass3"]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backup> => I<bool> (default: 1)

Whether to backup the original file to ORIG~.

=item * B<files>* => I<array[filename]>

=item * B<passwords> => I<array[str]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-PDFUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDFUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDFUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<add-pdf-password>.

L<remove-pdf-password>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
