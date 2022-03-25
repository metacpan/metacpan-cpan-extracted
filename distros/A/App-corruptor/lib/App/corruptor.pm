package App::corruptor;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-13'; # DATE
our $DIST = 'App-corruptor'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

my %argspec0_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*', of=>'filename*'],
        req => 1,
        pos => 0,
        slurpy => 1,
    },
);

$SPEC{corruptor} = {
    v => 1.1,
    summary => 'Corrupt files by writing some random bytes/blocks to them',
    description => <<'_',

This utility can be used in disk/filesystem testing. It corrupts files by
writing random bytes/blocks to them.

_
    args => {
        %argspec0_files,
        # XXX arg: block mode or byte mode
        proportion => {
            summary => 'How much random data is written '.
                'as proportion of file size (in percent)',
            schema => ['percent*', xmin=>0, max=>100],
            req => 1,
            cmdline_aliases => {p=>{}},
        },
    },
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'Corrupt two files by writing 1% random bytes',
            argv => ['disk.img', 'disk2.img', '-p1%'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url=>'http://jrs-s.net/2016/05/09/testing-copies-equals-n-resiliency/'},
    ],
};
sub corruptor {
    my %args = @_;

    my $num_errors = 0;
    for my $file (@{$args{files}}) {
        unless (-f $file) {
            warn "corruptor: No such file '$file', skipped\n";
            $num_errors++;
            next;
        }
        my $filesize = -s _;
        unless ($filesize) {
            warn "corruptor: File '$file' is zero-sized, skipped\n";
        }
      WRITE:
        {
            log_info("Opening file '%s'", $file);
            open my $fh, "+<", $file or do {
                warn "corruptor: Can't open '$file': $!\n";
                $num_errors++;
                next;
            };
            my $n = int($filesize * $args{proportion});
            $n = 1 if $n < 1;
          CORRUPT:
            {
                if ($args{-dry_run}) {
                    log_info("[DRY] Writing %d random byte(s) to file ...", $n);
                    last CORRUPT;
                }
                log_info("Writing %d random byte(s) to file ...", $n);
                for (1..$n) {
                    my $pos = int(rand() * $filesize);
                    seek $fh, $pos, 0;
                    print $fh chr(rand() * 256);
                }
            }
            close $fh or do {
                warn "corruptor: Can't write '$file': $!\n";
                $num_errors++;
                next;
            };
        }
    }

    [$num_errors == @{$args{files}} ? 500 : 200,
     $num_errors == 0 ? "All OK" : $num_errors < @{$args{files}} ? "OK (some files failed)" : "All files failed",
     undef,
     {'cmdline.exit_code' => $num_errors ? 1:0}];
}

sub _corruptor {
    my ($which, %args) = @_;

    my $num_errors = 0;
    for my $file (@{$args{files}}) {
        unless (-f $file) {
            warn "corruptor-$which: No such file '$file', skipped\n";
            $num_errors++;
            next;
        }
        my $filesize = -s _;
        unless ($filesize) {
            warn "corruptor-$which: File '$file' is zero-sized, skipped\n";
        }
      WRITE:
        {
            log_info("Opening file '%s'", $file);
            open my $fh, "+<", $file or do {
                warn "corruptor: Can't open '$file': $!\n";
                $num_errors++;
                next;
            };
            seek $fh, 0, 0;
            for (1..$filesize) {
                if ($which eq 'total') {
                    print $fh chr(rand() * 256);
                } elsif ($which eq 'zero') {
                    print $fh "\0";
                } else {
                    die "BUG: Unknown destroy mode";
                }
            }
            close $fh or do {
                warn "corruptor-$which: Can't write '$file': $!\n";
                $num_errors++;
                next;
            };
        }
    }

    [$num_errors == @{$args{files}} ? 500 : 200,
     $num_errors == 0 ? "All OK" : $num_errors < @{$args{files}} ? "OK (some files failed)" : "All files failed",
     undef,
     {'cmdline.exit_code' => $num_errors ? 1:0}];
}

$SPEC{corruptor_total} = {
    v => 1.1,
    summary => 'Destroy files by replacing their contents with random data',
    args => {
        %argspec0_files,
    },
};
sub corruptor_total {
    my %args = @_;
    _corruptor('total', %args);
}

$SPEC{corruptor_zero} = {
    v => 1.1,
    summary => 'Destroy files by replacing their contents with zero bytes (nulls)',
    args => {
        %argspec0_files,
    },
};
sub corruptor_zero {
    my %args = @_;
    _corruptor('zero', %args);
}

1;
# ABSTRACT: Corrupt files by writing some random bytes/blocks to them

__END__

=pod

=encoding UTF-8

=head1 NAME

App::corruptor - Corrupt files by writing some random bytes/blocks to them

=head1 VERSION

This document describes version 0.003 of App::corruptor (from Perl distribution App-corruptor), released on 2022-03-13.

=head1 FUNCTIONS


=head2 corruptor

Usage:

 corruptor(%args) -> [$status_code, $reason, $payload, \%result_meta]

Corrupt files by writing some random bytesE<sol>blocks to them.

Examples:

=over

=item * Corrupt two files by writing 1% random bytes:

 corruptor(files => ["disk.img", "disk2.img"], proportion => "1%");

=back

This utility can be used in disk/filesystem testing. It corrupts files by
writing random bytes/blocks to them.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>

=item * B<proportion>* => I<percent>

How much random data is written as proportion of file size (in percent).


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 corruptor_total

Usage:

 corruptor_total(%args) -> [$status_code, $reason, $payload, \%result_meta]

Destroy files by replacing their contents with random data.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 corruptor_zero

Usage:

 corruptor_zero(%args) -> [$status_code, $reason, $payload, \%result_meta]

Destroy files by replacing their contents with zero bytes (nulls).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<files>* => I<array[filename]>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-corruptor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-corruptor>.

=head1 SEE ALSO


L<http://jrs-s.net/2016/05/09/testing-copies-equals-n-resiliency/>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-corruptor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
