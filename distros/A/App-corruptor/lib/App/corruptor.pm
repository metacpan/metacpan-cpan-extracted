package App::corruptor;

our $DATE = '2017-08-10'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{corruptor} = {
    v => 1.1,
    summary => 'Corrupt files by writing random bytes/blocks to them',
    description => <<'_',

This utility can be used in disk/filesystem testing. It corrupts files by
writing random bytes/blocks to them.

_
    args => {
        files => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'file',
            schema => ['array*', of=>'filename*'],
            req => 1,
            pos => 0,
            greedy => 1,
        },
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

1;
# ABSTRACT: Corrupt files by writing random bytes/blocks to them

__END__

=pod

=encoding UTF-8

=head1 NAME

App::corruptor - Corrupt files by writing random bytes/blocks to them

=head1 VERSION

This document describes version 0.001 of App::corruptor (from Perl distribution App-corruptor), released on 2017-08-10.

=head1 FUNCTIONS


=head2 corruptor

Usage:

 corruptor(%args) -> [status, msg, result, meta]

Corrupt files by writing random bytes/blocks to them.

Examples:

=over

=item * Corrupt two files by writing 1% random bytes:

 corruptor( files => ["disk.img", "disk2.img"], proportion => "1%");

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

Pass -dry_run=>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-corruptor>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-corruptor>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-corruptor>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<http://jrs-s.net/2016/05/09/testing-copies-equals-n-resiliency/>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
