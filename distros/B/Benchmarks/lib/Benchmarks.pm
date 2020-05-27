package Benchmarks;
use strict;
use warnings;
use Benchmark qw/ :hireswallclock /;
our $VERSION = '0.11';

sub import {
    my ($class, $code, $count, $style, $title) = @_;

    Benchmark->export_to_level(1, $class, ':all');

    return unless $code;
    return unless ref $code eq 'CODE';

    my ($ret, $runtime_count, $runtime_style, $runtime_title)  = $code->();

    return if !defined $ret;

    $count = defined($runtime_count) ? $runtime_count
           : defined($count)         ? $count
           : -1;
    $style = defined($runtime_style) ? $runtime_style
           : defined($style)         ? $style
           : 'auto';
    $title = defined($runtime_title) ? $runtime_title
           : defined($title)         ? $title
           : undef;

    _run_benchmark($count, $ret, $style, $title);
}

sub _run_benchmark {
    my ($count, $ret, $style, $title) = @_;

    my $ref_ret = ref $ret;

    if ( !$ref_ret || $ref_ret eq 'CODE' ) {
        Benchmark::timethis($count, $ret, $title, $style);
    }
    elsif ( $ref_ret eq 'HASH' ) {
        Benchmark::cmpthese($count, $ret, $style);
    }
    else {
        die "The CODE returned wrong retval.";
    }
}

1;

__END__

=head1 NAME

Benchmarks - The comparison benchmarker


=head1 SYNOPSIS

    use Benchmarks sub {
        my $x = 2;
        +{
            times => sub { $x * $x * $x * $x },
            raise => sub { $x ** 4 },
        };
    };


=head1 DESCRIPTION

B<Benchmarks> is the L<Benchamark> wrapper for comparing routines easily.

When this module was loaded, all you need to do is pass the CODE reference that returns the hash reference.

    use Benchmarks sub {
        +{
            'routine_name_1' => sub { '... some code ...' },
            'routine_name_2' => sub { '... some code ...' },
        };
    };

Then the comparison will be invoked and show the result like below.

    Benchmark: running raise, times for at least 1 CPU seconds...
         raise: -1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 8895180.37/s (n=9517843)
         times:  2 wallclock secs ( 1.10 usr +  0.00 sys =  1.10 CPU) @ 4051316.36/s (n=4456448)
               Rate times raise
    times 4051316/s    --  -54%
    raise 8895180/s  120%    --

=head2 PURE BENCHMARK

B<Benchmarks> can show a pure benchmark(NOT to compare) like below.

    use Benchmarks sub {
        my $x = 2;
        sub { $x * $x * $x * $x }; # only one code
    };

then the result like this.

    timethis for 1:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 4164904.67/s (n=4456448)

=head2 MORE FUNCTIONS

C<Benchmarks> exports B<*ALL*> functions from C<Benchmark>. You can use C<Benchmarks> module as same as C<Benchmark> module.

    use Benchmarks;

    warn timestr(
        countit(1, sub { bless +{}, 'Foo' } )
    );

More information about functions: L<https://metacpan.org/pod/Benchmark#Standard-Exports> and L<https://metacpan.org/pod/Benchmark#Optional-Exports>

=head2 BENCHMARKS ARGS

When you use C<Benchmarks>, you can throw several args like below.

    use Benchmarks sub {
        # benchmark hash or code.
    }, COUNT, STYLE, TITLE;

example STYLE:

    use Benchmarks sub {
        my $x = 2;
        +{
            times => sub { $x * $x },
            raise => sub { $x ** 2 },
        };
    }, 100, "none";

example STYLE and TITLE:

    use Benchmarks sub {
        my $x = 2;
        sub { $x * $x };
    }, 100, 'all', '2 times';

You can pass(return) these args at runtime.

    use Benchmarks sub {
        my $x = 2;
        sub { $x * $x }, 100, 'all', '2 times';
    };


=head2 BENCHMARK TEMPLATE

This module includes the L<penchmarks> command. It's generator of the C<Benchmarks> template.

    $ penchmarks GENERATE_BENCHMARK_FILE_PATH

Then you can edit the C<GENERATE_BENCHMARK_FILE_PATH> file and run it.


=head1 REPOSITORY

Benchmarks is hosted on github
L<http://github.com/bayashi/Benchmarks>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Benchmark>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
