package App::CreateSparseFile;

our $DATE = '2017-11-10'; # DATE
our $VERSION = '0.080'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::MoreUtil qw(file_exists);
use IO::Prompt::I18N qw(confirm);

our %SPEC;

$SPEC{create_sparse_file} = {
    v => 1.1,
    summary => 'Create sparse file',
    description => <<'_',

Sparse file is a file with a predefined size (sometimes large) but does not yet
allocate all its (blank) data on disk. Sparse file is a feature of filesystem.

I usually create sparse file when I want to create a large disk image but do not
want to preallocate its data yet. Creating a sparse file should be virtually
instantaneous.

_
    args => {
        name => {
            schema => ['str*'],
            req => 1,
            pos => 0,
        },
        size => {
            summary => 'Size (e.g. 10K, 22.5M)',
            schema => ['str*'],
            cmdline_aliases => { s => {} },
            req => 1,
            pos => 1,
        },
        interactive => {
            summary => 'Whether or not the program should be interactive',
            schema => 'bool',
            default => 1,
            description => <<'_',

If set to false then will not prompt interactively and usually will proceed
(unless for dangerous stuffs, in which case will bail immediately.

_
        },
        overwrite => {
            summary => 'Whether to overwrite existing file',
            schema => 'bool',
            default => 0,
            description => <<'_',

If se to true then will overwrite existing file without warning. The default is
to prompt, or bail (if not interactive).

_
        },
    },
    examples => [
        {
            argv => [qw/file.bin 30G/],
            summary => 'Create a sparse file called file.bin with size of 30GB',
            test => 0,
            'x.doc.show_result' => 0, # to avoid having PWP:Rinci execute our function to get result
        },
    ],
    links => [
        {url => 'prog:fallocate'},
    ],
};
sub create_sparse_file {
    my %args = @_;

    my $interactive = $args{interactive} // 1;

    # TODO: use Parse::Number::WithPrefix::EN
    my $size = $args{size} // 0;
    return [400, "Invalid size, please specify num or num[KMGT]"]
        unless $size =~ /\A(\d+(?:\.\d+)?)(?:([A-Za-z])[Bb]?)?\z/;
    my ($num, $suffix) = ($1, $2);
    if ($suffix) {
        if ($suffix =~ /[Kk]/) {
            $num *= 1024;
        } elsif ($suffix =~ /[Mm]/) {
            $num *= 1024**2;
        } elsif ($suffix =~ /[Gg]/) {
            $num *= 1024**3;
        } elsif ($suffix =~ /[Tt]/) {
            $num *= 1024**4;
        } else {
            return [400, "Unknown number suffix '$suffix'"];
        }
    }
    $num = int($num);

    my $fname = $args{name};

    if (file_exists $fname) {
        if ($interactive) {
            return [200, "Cancelled"]
                unless confirm "Confirm overwrite existing file", {default=>0};
        } else {
            return [409, "File already exists"] unless $args{overwrite};
        }
        unlink $fname or return [400, "Can't unlink $fname: $!"];
    } else {
        if ($interactive) {
            my $s = $suffix ? "$num ($size)" : $num;
            return [200, "Cancelled"]
                unless confirm "Confirm create '$fname' with size $s";
        }
    }

    open my($fh), ">", $fname or return [500, "Can't create $fname: $!"];
    if ($num > 0) {
        seek $fh, $num-1, 0;
        print $fh "\0";
    }
    [200, "Done"];
}

1;
# ABSTRACT: Create sparse file

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CreateSparseFile - Create sparse file

=head1 VERSION

This document describes version 0.080 of App::CreateSparseFile (from Perl distribution App-CreateSparseFile), released on 2017-11-10.

=head1 SYNOPSIS

See L<create-sparse-file>.

=head1 FUNCTIONS


=head2 create_sparse_file

Usage:

 create_sparse_file(%args) -> [status, msg, result, meta]

Create sparse file.

Examples:

=over

=item * Create a sparse file called file.bin with size of 30GB:

 create_sparse_file( name => "file.bin", size => "30G");

=back

Sparse file is a file with a predefined size (sometimes large) but does not yet
allocate all its (blank) data on disk. Sparse file is a feature of filesystem.

I usually create sparse file when I want to create a large disk image but do not
want to preallocate its data yet. Creating a sparse file should be virtually
instantaneous.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<interactive> => I<bool> (default: 1)

Whether or not the program should be interactive.

If set to false then will not prompt interactively and usually will proceed
(unless for dangerous stuffs, in which case will bail immediately.

=item * B<name>* => I<str>

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite existing file.

If se to true then will overwrite existing file without warning. The default is
to prompt, or bail (if not interactive).

=item * B<size>* => I<str>

Size (e.g. 10K, 22.5M).

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CreateSparseFile>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CreateSparseFile>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CreateSparseFile>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<fallocate>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
