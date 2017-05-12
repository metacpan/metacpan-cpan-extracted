package Benchmark::Confirm;
use strict;
use warnings;

our $VERSION = '1.00';

=head1 NAME

Benchmark::Confirm - take a Benchmark and confirm returned values


=head1 SYNOPSIS

for example, it is ordinary to execute benchmark script...

    perl some_benchmark.pl

and use Benchmark::Confirm

    perl -MBenchmark::Confirm some_benchmark.pl

then you get the result of benchmark and the confirmination.

    Benchmark: timing 1 iterations of Name1, Name2, Name3...
         Name1:  0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
                (warning: too few iterations for a reliable count)
         Name2:  0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
                (warning: too few iterations for a reliable count)
         Name3:  0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
                (warning: too few iterations for a reliable count)
                        Rate Name3 Name1 Name2
    Name3 10000/s    --    0%    0%
    Name1 10000/s    0%    --    0%
    Name2 10000/s    0%    0%    --
    ok 1
    ok 2
    ok 3
    1..3

See the last 4 lines, these are the result of confirmation.


=head1 DESCRIPTION

B<Benchmark::Confirm> displays a confirmation after benchmarks that the each values from benchmark codes are equivalent or not.

All you have to do is to use C<Benchmark::Confirm> instead of C<Benchmark>.

However, if you write some benchmarks in the one script, you should call some methods from C<Benchmark::Confirm>. for more details see below METHODS section.


=head1 METHODS

See L<Benchmark#Standard_Exports> and L<Benchmark#Optional_Exports> sections.

Moreover, B<atonce> and B<reset_confirm> these functions are only for C<Benchmark::Confirm>.

=head2 atonce

C<atonce> function confirms values manually.

You can use this function when you write some benchmarks in one script. Or you shuld use C<reset> function instead on between some benchmarks.

    use strict;
    use warnings;

    use Benchmark::Confirm qw/timethese/;

    {
        my $result = timethese( 1 => +{
            Name1 => sub { "something" },
            Name2 => sub { "something" },
            Name3 => sub { "something" },
        });
    }

    Benchmark::Confirm->atonce;

    {
        my $result = timethese( 1 => +{
            Name1 => sub { 1 },
            Name2 => sub { 1 },
            Name3 => sub { 1 },
        });
    }

=head2 reset_confirm

This function resets stacks of returned value.


=head1 IMPORT OPTIONS

=head2 TAP

If you want to get valid TAP result, you should add import option C<TAP>.

    perl -MBenchmark::Confirm=TAP some_benchmark.pl

Then you get results as valid TAP like below.

    # Benchmark: timing 1 iterations of Name1, Name2, Name3...
    #      Name1:  0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
    #             (warning: too few iterations for a reliable count)
    #      Name2:  0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
    #             (warning: too few iterations for a reliable count)
    #      Name3:  0 wallclock secs ( 0.00 usr +  0.00 sys =  0.00 CPU)
    #             (warning: too few iterations for a reliable count)
    #                     Rate Name3 Name1 Name2
    # Name3 10000/s    --    0%    0%
    # Name1 10000/s    0%    --    0%
    # Name2 10000/s    0%    0%    --
    ok 1
    ok 2
    ok 3
    1..3

=head2 no_plan

If you want to add more tests with benchmarks, you should use import option C<no_plan>.

    use Benchmark::Confirm qw/no_plan timethese cmpthese/;

    my $result = timethese( 1 => +{
        Name1 => sub { "something" },
        Name2 => sub { "something" },
        Name3 => sub { "something" },
    });

    cmpthese $result;

    ok 1, 'additionaly';

Don't worry, C<Test::More::done_testing> invokes in C<END> block of Benchmark::Confirm. So you don't need write that.


=head1 CAVEATS

If benchmark code returns CODE reference, then C<Benchmark::Confirm> treats it as string value: 'CODE'. This may change in future releases.


=head1 REPOSITORY

Benchmark::Confirm is hosted on github
<http://github.com/bayashi/Benchmark-Confirm>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Benchmark>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

use Benchmark;
use Test::More;

my $capture;

sub import {
    my $class = shift;

    my $caller = caller;

    my @imports = ($class);
    for my $func (@_) {
        next unless $func;
        if ($func eq 'TAP') {
            require IO::Capture::Stdout;
            $capture = IO::Capture::Stdout->new;
            $capture->start;
        }
        elsif ($func eq 'no_plan') {
            no strict 'refs'; ## no critic
            for my $f ( @Test::More::EXPORT ) {
                *{"${caller}::$f"} = \&{"Test::More::$f"};
            }
        }
        else {
            push @imports, $func;
        }
    }
    Benchmark->export_to_level(1, @imports);
}

our @CONFIRMS;

END {
    if (ref $capture eq 'IO::Capture::Stdout') {
        $capture->stop;
        while ( my $line = $capture->read ) {
            print "# ${line}"; # valid TAP
        }
    }
    if (@CONFIRMS > 1) {
        atonce();
        Test::More::done_testing();
    }
}

sub atonce {
    my $expect = _normalize(shift @CONFIRMS);
    Test::More::ok(1);

    for my $got (@CONFIRMS) {
        Test::More::is_deeply( _normalize($got), $expect );
    };

    reset_confirm();
}

sub _normalize {
    my $element = shift;
    (ref $element eq 'CODE') ? 'CODE' : [$element];
}

sub reset_confirm {
    @CONFIRMS = ();
}


package # hide from PAUSE
    Benchmark;
use strict;
no warnings 'redefine';

# based Benchmark 1.13
sub runloop {
    my($n, $c) = @_;

    $n+=0; # force numeric now, so garbage won't creep into the eval
    croak "negative loopcount $n" if $n<0;
    confess usage unless defined $c;
    my($t0, $t1, $td); # before, after, difference

    # find package of caller so we can execute code there
    my($curpack) = caller(0);
    my($i, $pack)= 0;
    while (($pack) = caller(++$i)) {
        last if $pack ne $curpack;
    }

    my ($subcode, $subref, $confirmref);
    if (ref $c eq 'CODE') {
        $subcode = "sub { for (1 .. $n) { local \$_; package $pack; &\$c; } }";
        $subref  = eval $subcode; ## no critic
        $confirmref = eval "sub { package $pack; &\$c; }"; ## no critic
    }
    else {
        $subcode = "sub { for (1 .. $n) { local \$_; package $pack; $c;} }";
        $subref  = _doeval($subcode);
        $confirmref = _doeval("sub { package $pack; $c; }");
    }
    croak "runloop unable to compile '$c': $@\ncode: $subcode\n" if $@;
    print STDERR "runloop $n '$subcode'\n" if $Benchmark::Debug;

    push @Benchmark::Confirm::CONFIRMS, $confirmref->();

    # Wait for the user timer to tick.  This makes the error range more like 
    # -0.01, +0.  If we don't wait, then it's more like -0.01, +0.01.  This
    # may not seem important, but it significantly reduces the chances of
    # getting a too low initial $n in the initial, 'find the minimum' loop
    # in &countit.  This, in turn, can reduce the number of calls to
    # &runloop a lot, and thus reduce additive errors.
    my $tbase = Benchmark->new(0)->[1];
    while ( ( $t0 = Benchmark->new(0) )->[1] == $tbase ) {} ;
    $subref->();
    $t1 = Benchmark->new($n);
    $td = &timediff($t1, $t0);
    timedebug("runloop:",$td);
    $td;
}

1;
