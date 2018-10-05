## no critic: InputOutput::RequireEncodingWithUTF8Layer

package Bencher::Mark;

our $DATE = '2018-10-05'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(timethis timethese cmpthese);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub timethis {
    my ($count, $code) = @_;
    timethese($count, {
        'code' => $code,
    });
}

sub timethese {
    my ($count, $codes) = @_;

    my $scenario = {
        participants => [],
    };

    for my $name (sort keys %$codes) {
        my $code = $codes->{$name};
        my $participant = {
            name => $name,
        };
        if (ref $code eq 'CODE') {
            $participant->{code} = $code;
        } else {
            if ($code =~ /\A\w+(?:::\w+)*\s*\(/s) {
                # quite an assumption!
                $participant->{fcall_template} = $code;
            } else {
                $participant->{code_template} = $code;
            }
        }
        push @{ $scenario->{participants} }, $participant;
    }

    require Bencher::Backend;
    my $res = Bencher::Backend::bencher(
        action => "bench",
        scenario => $scenario,
    );
    die "Can't benchmark: $res->[0] - $res->[1]" unless $res->[0] == 200;

    my @orig_layers = PerlIO::get_layers(*STDOUT);
    binmode(STDOUT, ":utf8") unless grep { $_ eq "utf8" } @orig_layers;
    print Bencher::Backend::format_result($res);
    binmode(STDOUT)          unless grep { $_ eq "utf8" } @orig_layers;
    $res;
}

sub cmpthese {
    goto &timethese;
}

1;
# ABSTRACT: Benchmark like Benchmark.pm

__END__

=pod

=encoding UTF-8

=head1 NAME

Bencher::Mark - Benchmark like Benchmark.pm

=head1 VERSION

This document describes version 0.001 of Bencher::Mark (from Perl distribution Bencher-Mark), released on 2018-10-05.

=head1 SYNOPSIS

 use Bencher::Mark qw(:all);

 # You can specify undef for $count

 timethis($count, $code);

 timethese($count, {
     Name1 => '... code ...', # specify code as string
     Name2 => sub { ... }   , # or coderef
 });

 cmpthese($count, {
     Name1 => '... code ...',
     Name2 => sub { ... }   ,
 });

=head1 DESCRIPTION

B<EXPERIMENTAL.>

This is an experiment to make writing benchmarks using L<Bencher> easier. This
module offers an interface like L<Benchmark>.pm, but internally it constructs a
scenario, feeds it to L<Bencher::Backend>, then displays the formatted result.

=head1 FUNCTIONS

=head2 timethis

=head2 timethese

=head2 cmpthese

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Mark>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Mark>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Mark>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<bencher>, L<Bencher>, C<Bencher::Manual::*>

L<Benchmark>, L<Dumbbench>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
