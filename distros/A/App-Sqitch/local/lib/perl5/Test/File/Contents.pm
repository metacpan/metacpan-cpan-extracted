package Test::File::Contents;

use 5.008003;
use warnings;
use strict;

=encoding utf8

=head1 Name

Test::File::Contents - Test routines for examining the contents of files

=cut

our $VERSION = '0.23';

use Test::Builder;
use Digest::MD5;
use File::Spec;
use Text::Diff;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    file_contents_eq
    file_contents_eq_or_diff
    file_contents_ne
    file_contents_like
    file_contents_unlike
    file_md5sum_is
    files_eq
    files_eq_or_diff

    file_contents_is
    file_contents_isnt
    file_md5sum
    file_contents_identical
);

my $Test = Test::Builder->new;

=head1 Synopsis

  use Test::File::Contents;

  file_contents_eq         $file,  $string,  $description;
  file_contents_eq_or_diff $file,  $string,  $description;
  file_contents_like       $file,  qr/foo/,  $description;
  file_md5sum_is           $file,  $md5sum,  $description;
  files_eq                 $file1, $file2,   $description;
  files_eq_or_diff         $file1, $file2,   $description;

=head1 Description

Got an app that generates files? Then you need to test those files to make
sure that their contents are correct. This module makes that easy. Use its
test functions to make sure that the contents of files are exactly what you
expect them to be.

=head1 Interface

=head2 Options

These test functions take an optional hash reference of options which may
include one or more of these options:

=over

=item C<encoding>

The encoding in which the file is encoded. This will be used in an I/O layer
to read in the file, so that it can be properly decoded to Perl's internal
representation. Examples include C<UTF-8>, C<iso-8859-3>, and C<cp1252>. See
L<Encode::Supported> for a list of supported encodings. May also be specified
as a layer, such as ":utf8" or ":raw". See L<perlio> for a complete list of
layers.

Note that it's important to specify the encoding if you have non-ASCII
characters in your file. And the value to be compared against (the string
argument to C<file_contents_eq()> and the regular expression argument to
C<file_contents_like()>, for example, must be decoded to Perl's internal
form. The simplest way to do so use to put

  use utf8;

In your test file and write it all in C<UTF-8>. For example:

  use utf8;
  use Test::More tests => 1;
  use Test::File::Contents;

  file_contents_eq('utf8.txt',   'ååå', { encoding => 'UTF-8' });
  file_contents_eq('latin1.txt', 'ååå', { encoding => 'UTF-8' });

=item C<style>

The style of diff to output in the diagnostics in the case of a failure
in C<file_contents_eq_or_diff>. The possible values are:

=over

=item Unified

=item Context

=item OldStyle

=item Table

=back

=item C<context>

Determines the amount of context displayed in diagnostic diff output. If you
need to seem more of the area surrounding different lines, pass this option to
determine how many more links you'd like to see.

=back

=head2 Test Functions

=head3 file_contents_eq

  file_contents_eq $file, $string, $description;
  file_contents_eq $file, $string, { encoding => 'UTF-8' };
  file_contents_eq $file, $string, { encoding => ':bytes' }, $description;

Checks that the file's contents are equal to a string. Pass in a Unix-style
file name and it will be converted for the local file system. Supported
L<options|/Options>:

=over

=item C<encoding>

=back

The old name for this function, C<file_contents_is>, remains as an
alias.

=cut

sub file_contents_eq($$;$$) {
    my ($file, $string, $desc, $opts) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';
    return _compare(
        $file,
        sub { shift eq $string },
        $opts,
        $desc || "$file contents equal to string",
        "File $file contents not equal to '$string'",
    );
}

*file_contents_is = \&file_contents_eq;

=head3 file_contents_eq_or_diff

  file_contents_eq_or_diff $file, $string, $description;
  file_contents_eq_or_diff $file, $string, { encoding => 'UTF-8' };
  file_contents_eq_or_diff $file, $string, { style    => 'context' }, $description;

Like C<file_contents_eq()>, only in the event of failure, the diagnostics will
contain a diff instead of the full contents of the file. This can make it
easier to test the contents of very large text files, and where only a subset
of the lines are different. Supported L<options|/Options>:

=over

=item C<encoding>

=item C<style>

=item C<context>

=back

=cut

sub file_contents_eq_or_diff {
    my ($file, $want, $desc, $opts) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';
    my $fn = _resolve($file);
    $desc ||= "$file contents equal to string";

    my $have = _slurp($fn, $opts->{encoding});
    if (defined $have) {
        return $Test->ok($have eq $want, $desc) || $Test->diag(
            diff \$have, \$want, {
                CONTEXT     => $opts->{context},
                STYLE       => $opts->{style},
                FILENAME_A  => $file,
                FILENAME_B  => "Want",
            }
        );
    } else {
        return $Test->ok(0, $desc)
            || $Test->diag("    Could not open file $file: $!");
    }
}

=head3 file_contents_ne

  file_contents_ne $file, $string, $description;
  file_contents_ne $file, $string, { encoding => 'UTF-8' };
  file_contents_ne $file, $string, { encoding => ':bytes' }, $description;

Checks that the file's contents do not equal a string. Pass in a Unix-style
file name and it will be converted for the local file system. Supported
L<options|/Options>:

=over

=item C<encoding>

=back

The old name for this function, C<file_contents_isnt>, remains as an alias.

=cut

sub file_contents_ne($$;$$) {
    my ($file, $string, $desc, $opts) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';
    return _compare(
        $file,
        sub { shift ne $string },
        $opts,
        $desc || "$file contents not equal to string",
        "File $file contents equal to '$string'",
    );
}

*file_contents_isnt = \&file_contents_ne;

=head3 file_contents_like

  file_contents_like $file, qr/foo/, $description;
  file_contents_like $file, qr/foo/, { encoding => 'UTF-8' };
  file_contents_like $file, qr/foo/, { encoding => ':bytes' }, $description;

Checks that the contents of a file match a regular expression. The regular
expression must be passed as a regular expression object created by C<qr//>.
Supported L<options|/Options>:

=over

=item C<encoding>

=back

=cut

sub file_contents_like($$;$$) {
    my ($file, $regex, $desc, $opts) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';
    return _compare(
        $file,
        sub { shift =~ /$regex/ },
        $opts,
        $desc || "$file contents match regex",
        "File $file contents do not match /$regex/",
    );
}

=head3 file_contents_unlike

  file_contents_unlike $file, qr/foo/, $description;
  file_contents_unlike $file, qr/foo/, { encoding => 'UTF-8' };
  file_contents_unlike $file, qr/foo/, { encoding => ':bytes' }, $description;

Checks that the contents of a file I<do not> match a regular expression. The
regular expression must be passed as a regular expression object created by
C<qr//>. Supported L<options|/Options>:

=over

=item C<encoding>

=back

=cut

sub file_contents_unlike($$;$$) {
    my ($file, $regex, $desc, $opts) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';
    return _compare(
        $file,
        sub { shift !~ /$regex/ },
        $opts,
        $desc || "$file contents do not match regex",
        "File $file contents match /$regex/",
    );
}

=head3 file_md5sum_is

  file_md5sum_is $file, $md5sum, $description;
  file_md5sum_is $file, $md5sum, { encoding => 'UTF-8' };
  file_md5sum_is $file, $md5sum, { encoding => ':bytes' }, $description;

Checks whether a file matches a given MD5 checksum. The checksum should be
provided as a hex string, for example, C<6df23dc03f9b54cc38a0fc1483df6e21>.
Pass in a Unix-style file name and it will be converted for the local file
system. Supported L<options|/Options>:

=over

=item C<encoding>

Probably not useful unless left unset or set to C<:raw>.

=back

The old name for this function, C<file_md5sum>, remains as an alias.

=cut

sub file_md5sum_is($$;$$) {
    my $arg_file = shift;
    my $file = _resolve($arg_file);
    my ($md5sum, $desc, $opts) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';
    return _compare(
        $file,
        sub { Digest::MD5->new->add(shift)->hexdigest eq $md5sum },
        $opts,
        $desc || "$arg_file has md5sum",
        "File $arg_file does not have md5 checksum $md5sum",
    );
}

*file_md5sum = \&file_md5sum_is;

=head3 files_eq

  files_eq $file1, $file2, $description;
  files_eq $file1, $file2, { encoding => 'UTF-8' };
  files_eq $file1, $file2, { encoding => ':bytes' }, $description;

Tests that the contents of two files are the same. Pass in a Unix-style file
name and it will be converted for the local file system. Supported
L<options|/Options>:

=over

=item C<encoding>

=back

The old name for this function, C<file_contents_identical>, remains as an
alias.

=cut

*file_contents_identical = \&files_eq;

sub files_eq($$;$$) {
    my ($f1, $f2, $desc, $opts) = @_;
    @_ = ($f1, $f2, $desc, $opts, sub {
        "    Files $f1 and $f2 are not the same."
    });
    goto &_files_eq;
}

=head3 files_eq_or_diff

  files_eq_or_diff $file1, $file2, $description;
  files_eq_or_diff $file1, $file2, { encoding => 'UTF-8' };
  files_eq_or_diff $file1, $file2, { style    => 'context' }, $description;

Like C<files_eq()>, this function tests that the contents of two files are the
same. Unlike C<files_eq()>, on failure this function outputs a diff of the two
files in the diagnostics. Supported L<options|/Options>:

=over

=item C<encoding>

=item C<style>

=item C<context>

=back

=cut

sub files_eq_or_diff($$;$$) {
    my ($f1, $f2, $desc, $opts) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';
    @_ = ($f1, $f2, $desc, $opts, sub {
        diff _resolve($f1), _resolve($f2), {
            CONTEXT     => $opts->{context},
            STYLE       => $opts->{style},
            FILENAME_A  => $f1,
            FILENAME_B  => $f2,
        };
    });
    goto &_files_eq;
}

sub _files_eq {
    my ($f1, $f2, $desc, $opts, $diag) = @_;
    ($opts, $desc) = ($desc, $opts) if ref $desc eq 'HASH';

    my @contents;
    for my $f ($f1, $f2) {
        my $file = _resolve($f);
        push @contents => _slurp($file, $opts->{encoding});
        next if defined $contents[-1];
        return $Test->ok(0, $desc)
            || $Test->diag("    Could not open file $file: $!");
    }

    return $Test->ok(
        $contents[0] eq $contents[1],
        $desc || "$f1 and $f2 contents are the same",
    ) || $Test->diag($diag->());
}

sub _compare {
    my $file = _resolve(shift);
    my ($code, $opts, $desc, $err) = @_;
    local $Test::Builder::Level = 2;
    my $contents = _slurp($file, $opts->{encoding});
    if (defined $contents) {
        return $Test->ok(scalar $code->($contents), $desc)
            || $Test->diag("    $err");
    } else {
        return $Test->ok(0, $desc)
            || $Test->diag("    Could not open file $file: $!");
    }
}

sub _slurp {
    my ($file, $encoding) = @_;
    my $layer = !$encoding  ? ''
        : $encoding =~ '^:' ? $encoding
        :                     ":encoding($encoding)";
    open my $fh, "<$layer", $file or return;
    return '' if eof $fh;
    # Don't use `local $/; return <$fh>;`, it does not work on Windows.
    # See https://rt.perl.org/Ticket/Display.html?id=127668 for details.
    return join '', <$fh>;
}

sub _resolve {
    $_[0] =~ m{/} ? File::Spec->catfile(split m{/}, shift) : shift;
}

1;

=head1 Authors

=over

=item * Kirrily Robert <skud@cpan.org>

=item * David E. Wheeler <david@justatheory.com>

=back

=head1 Support

This module is stored in an open L<GitHub
repository|https://github.com/theory/test-file-contents/>. Feel free to fork
and contribute!

Please file bug reports via L<GitHub
Issues|https://github.com/theory/test-file-contents/issues/> or by sending
mail to
L<bug-Test-File-Contents@rt.cpan.org|mailto:bug-Test-File-Contents@rt.cpan.org>.

=head1 Copyright and License

Copyright (c) 2004-2007 Kirrily Robert. Some Rights Reserved.
Copyright (c) 2007-2016 David E. Wheeler. Some Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
