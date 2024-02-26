package App::CreateRandomFile;

use 5.010001;
use strict;
use warnings;

use File::Util::Test qw(file_exists);
use IO::Prompt::I18N qw(confirm);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'App-CreateRandomFile'; # DIST
our $VERSION = '0.021'; # VERSION

our %SPEC;

sub _write_block {
    my ($fh, $block, $size) = @_;
    my $cursize = tell($fh);
    if ($cursize >= $size) {
        return;
    } elsif ($cursize + length($block) > $size) {
        print $fh substr($block, 0, $size - $cursize);
    } else {
        print $fh $block;
    }
}

$SPEC{create_random_file} = {
    v => 1.1,
    summary => 'Create file with random content',
    description => <<'_',

Create "random" file with a specified size. There are several choices of what
random data to use:

* random bytes, created using `rand()`
* repeated pattern supplied from `--pattern` command-line option

TODO:

* random bytes, source from /dev/urandom
* random lines from a specified file
* random byte sequences from a specified file
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
            default => 0,
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
        random_bytes => {
            schema => ['bool', is=>1],
        },
        patterns => {
            'x.name.is_plural' => 1,
            schema => ['array*', of=>['str*', min_len=>1], min_len=>1],
        },
    },
    examples => [
        {
            argv => [qw/file1 1M/],
            summary => 'Create a file of size 1MB containing random bytes',
            test => 0,
            'x.doc.show_result' => 0, # so PWP:Rinci doesn't execute our function to get result
        },
        {
            argv => [qw/file2 2M --random-bytes/],
            summary => 'Like the previous example (--random-bytes is optional)',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/file3 3.5K --pattern AABBCC/],
            summary => 'Create a file of size 3.5KB containing repeated pattern',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/file4 4K --pattern A --pattern B --pattern C/],
            summary => 'Create a file of size 4KB containing random sequences of A, B, C',
            test => 0,
            'x.doc.show_result' => 0,
        },
        #{
        #    argv => [qw[file4 4K --random-lines /usr/share/dict/words]],
        #    summary => 'Create a file of size ~4K containing random lines from /usr/share/dict/words',
        #    test => 0,
        #    'x.doc.show_result' => 0,
        #},
    ],
};
sub create_random_file {
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
    if ($args{patterns}) {
        my $pp = $args{patterns};
        if (@$pp > 1) {
            while (tell($fh) < $num) {
                my $block = "";
                while (length($block) < 4096) {
                    $block .= $pp->[rand @$pp];
                }
                _write_block($fh, $block, $num);
            }
        } else {
            my $block = "";
            while (length($block) < 4096) {
                $block .= $pp->[0];
            }
            while (tell($fh) < $num) {
                _write_block($fh, $block, $num);
            }
        }
    } else {
        while (tell($fh) < $num) {
            my $block = join("", map {chr(rand()*255)} 1..4096);
            _write_block($fh, $block, $num);
        }
    }

    [200, "Done"];
}

1;
# ABSTRACT: Create file with random content

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CreateRandomFile - Create file with random content

=head1 VERSION

This document describes version 0.021 of App::CreateRandomFile (from Perl distribution App-CreateRandomFile), released on 2023-11-20.

=head1 SYNOPSIS

See L<create-random-file>.

=head1 FUNCTIONS


=head2 create_random_file

Usage:

 create_random_file(%args) -> [$status_code, $reason, $payload, \%result_meta]

Create file with random content.

Examples:

=over

=item * Create a file of size 1MB containing random bytes:

 create_random_file(name => "file1", size => "1M");

=item * Like the previous example (--random-bytes is optional):

 create_random_file(name => "file2", size => "2M", random_bytes => 1);

=item * Create a file of size 3.5KB containing repeated pattern:

 create_random_file(name => "file3", size => "3.5K", patterns => ["AABBCC"]);

=item * Create a file of size 4KB containing random sequences of A, B, C:

 create_random_file(name => "file4", size => "4K", patterns => ["A", "B", "C"]);

=back

Create "random" file with a specified size. There are several choices of what
random data to use:

=over

=item * random bytes, created using C<rand()>

=item * repeated pattern supplied from C<--pattern> command-line option

=back

TODO:

=over

=item * random bytes, source from /dev/urandom

=item * random lines from a specified file

=item * random byte sequences from a specified file

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<interactive> => I<bool> (default: 0)

Whether or not the program should be interactive.

If set to false then will not prompt interactively and usually will proceed
(unless for dangerous stuffs, in which case will bail immediately.

=item * B<name>* => I<str>

(No description)

=item * B<overwrite> => I<bool> (default: 0)

Whether to overwrite existing file.

If se to true then will overwrite existing file without warning. The default is
to prompt, or bail (if not interactive).

=item * B<patterns> => I<array[str]>

(No description)

=item * B<random_bytes> => I<bool>

(No description)

=item * B<size>* => I<str>

Size (e.g. 10K, 22.5M).


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

Please visit the project's homepage at L<https://metacpan.org/release/App-CreateRandomFile>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CreateRandomFile>.

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

This software is copyright (c) 2023, 2017, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CreateRandomFile>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
