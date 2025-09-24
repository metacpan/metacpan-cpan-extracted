package App::nauniq;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-09-24'; # DATE
our $DIST = 'App-nauniq'; # DIST
our $VERSION = '0.112'; # VERSION

sub run {
    my %opts = @_;

    my $ifh; # input handle
    if (@ARGV) {
        my $fname = shift @ARGV;
        if ($fname eq '-') {
            $ifh = *STDIN;
        } else {
            open $ifh, "<", $fname or die "Can't open input file $fname: $!\n";
        }
    } else {
        $ifh = *STDIN;
    }

    my $phase = 2;
    my $ofh; # output handle
    if (@ARGV) {
        my $fname = shift @ARGV;
        if ($fname eq '-') {
            $ofh = *STDOUT;
        } else {
            open $ofh,
                ($opts{read_output} ? "+" : "") . ($opts{append} ? ">>" : ">"),
                    $fname
                or die "Can't open output file $fname: $!\n";
            if ($opts{read_output}) {
                seek $ofh, 0, 0;
                $phase = 1;
            }
        }
    } else {
        $ofh = *STDOUT;
    }

    my ($line, $memkey);
    my %mem;
    my $sub_reset_mem = sub {
        if ($opts{num_entries} > 0) {
            require Tie::Cache;
            tie %mem, 'Tie::Cache', $opts{num_entries};
        } else {
            %mem = ();
        }
    };
    $sub_reset_mem->();
    require Digest::MD5 if $opts{md5};
    no warnings; # we want to shut up 'substr outside of string'
    while (1) {
        if ($phase == 1) {
            # phase 1 is just reading the output file
            $line = <$ofh>;
            if (!$line) {
                $phase = 2;
                next;
            }
        } else {
            $line = <$ifh>;
            if (!$line) {
                last;
            }
        }
        if ($opts{forget_pattern} && $line =~ $opts{forget_pattern}) {
            $sub_reset_mem->();
        }

        $memkey = $opts{check_chars} > 0 ?
            substr($line, $opts{skip_chars}, $opts{check_chars}) :
                substr($line, $opts{skip_chars});
        $memkey = lc($memkey) if $opts{ignore_case};
        $memkey = Digest::MD5::md5($memkey) if $opts{md5};

        if ($phase == 2) {
            if ($mem{$memkey}) {
                print $ofh $line if $opts{show_repeated};
            } else {
                print $ofh $line if $opts{show_unique};
            }
        }

        $mem{$memkey} = 1;
    }
}


1;
# ABSTRACT: Non-adjacent uniq

__END__

=pod

=encoding UTF-8

=head1 NAME

App::nauniq - Non-adjacent uniq

=head1 VERSION

This document describes version 0.112 of App::nauniq (from Perl distribution App-nauniq), released on 2025-09-24.

=head1 SYNOPSIS

See the command-line script L<nauniq>.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-nauniq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-nauniq>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-nauniq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
