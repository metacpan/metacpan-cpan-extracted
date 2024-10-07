package App::Greple::stripe;

use 5.024;
use warnings;

our $VERSION = "0.99";

=encoding utf-8

=head1 NAME

App::Greple::stripe - Greple zebra stripe module

=head1 SYNOPSIS

    greple -Mstripe [ module options -- ] ...

=head1 VERSION

Version 0.99

=head1 DESCRIPTION

App::Greple::stripe is a module for B<greple> to show matched text
in zebra striping fashion.

The following command matches two consecutive lines.

    greple -E '(.+\n){1,2}' --face +E

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/normal.png">
</p>

However, each matched block is colored by the same color, so it is not
clear where the block breaks.  One way is to explicitly display the
blocks using the C<--blockend> option.

    greple -E '(.+\n){1,2}' --face +E --blockend=--

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/blockend.png">
</p>

Using the stripe module, blocks matching the same pattern are colored
with different colors of the similar color series.

    greple -Mstripe -E '(.+\n){1,2}' --face +E

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/stripe.png">
</p>

By default, two color series are prepared. Thus, when multiple
patterns are searched, an even-numbered pattern and an odd-numbered
pattern are assigned different color series.  When multiple patterns
are specified, only lines matching all patterns will be output, so the
C<--need=1> option is required to relax this condition.

    greple -Mstripe -E '.*[02468]$' -E '.*[13579]$' --need=1

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/random.png">
</p>

If you want to use three series with three patterns, specify C<step>
when calling the module.

    greple -Mstripe::set=step=3 --need=1 -E p1 -E p2 -E p3 ...

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-stiripe/refs/heads/main/images/step-3.png">
</p>

=head1 MODULE OPTIONS

There are options specific to the B<stripe> module.  They can be
specified either at the time of module declaration or as options
following the module declaration and ending with C<-->.

The following two commands have exactly the same effect.

    greple -Mstripe=set=step=3

    greple -Mstripe --step=3 --

=over 7

=item B<-Mstep::set>=B<step>=I<n>

=item B<--step>=I<n>

Set the step count to I<n>.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use List::Util qw(max pairmap first);
use Hash::Util qw(lock_keys);
use Scalar::Util;
*is_number = \&Scalar::Util::looks_like_number;
use Data::Dumper;

our %opt = (
    step  => 2,
);
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

sub hash_to_spec {
    pairmap {
	$a = "$a|${\(uc(substr($a, 0, 1)))}";
	my $ref = ref $b;
	if    (not defined $b)   { "$a!"  }
	elsif ($ref eq 'SCALAR') { "$a!"  }
	elsif (is_number($b))    { "$a=f" }
	else                     { "$a=s" }
    } shift->%*;
}

my @series = (
    [ qw(/544 /533) ],
    [ qw(/454 /353) ],
    [ qw(/445 /335) ],
    [ qw(/554 /553) ],
    [ qw(/545 /535) ],
    [ qw(/554 /553) ],
);

sub mod_argv {
    my($mod, $argv) = @_;
    my @my_argv;
    if (@$argv and $argv->[0] !~ /^-M/ and
	defined(my $i = first { $argv->[$_] eq '--' } keys @$argv)) {
	splice @$argv, $i, 1; # remove '--'
	@my_argv = splice @$argv, 0, $i;
    }
    ($mod, \@my_argv, $argv);
}

sub getopt {
    my($argv, $opt) = @_;
    return if @{ $argv //= [] } == 0;
    use Getopt::Long qw(GetOptionsFromArray);
    Getopt::Long::Configure qw(bundling);
    GetOptionsFromArray $argv, $opt, hash_to_spec $opt
	or die "Option parse error.\n";
}

sub finalize {
    our($mod, $my_argv, $argv) = mod_argv @_;
    getopt $my_argv, \%opt;
    my @default = qw(--stripe-postgrep);
    my @cm;
    for my $i (0, 1) {
	for my $s (0 .. $opt{step} - 1) {
	    push @cm, $series[$s % @series]->[$i];
	}
    }
    local $" = ',';
    $mod->setopt(default => join(' ', @default, "--cm=@cm"));
}

#
# Increment each index by $step
#
sub stripe {
    my $grep = shift;
    my $step = $opt{step};
    if ($step == 0) {
	$step = _max_index($grep) + 1;
    }
    my @counter = (-$step .. -1);
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    my $mod = $m->[2] % $step;
	    $m->[2] = ($counter[$mod] += $step);
	}
    }
}

sub _max_index {
    my $grep = shift;
    my $max = 0;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	$max = max($max, map($_->[2], @match));
    }
}

sub set {
    while (my($key, $val) = splice @_, 0, 2) {
	next if $key eq &::FILELABEL;
	die "$key: Invalid option.\n" if not exists $opt{$key};
	$opt{$key} = $val;
    }
}

1;

__DATA__

builtin stripe-debug! $debug

option --stripe-postgrep \
	 --postgrep &__PACKAGE__::stripe
