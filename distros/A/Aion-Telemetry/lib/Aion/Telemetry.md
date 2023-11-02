# NAME

Aion::Telemetry - measures the time the program runs between specified points

# VERSION

0.0.1

# SYNOPSIS

```perl
use Aion::Telemetry;

my $mark = refmark;

my $sum = 0;
$sum += $_ for 1 .. 1000;

undef $mark;

my $s = << 'END';
Ref Report -- Total time: 0.\d+ ms
   Count          Time  Percent  Interval
----------------------------------------------
       1  0.\d+ ms  100.00%  main::__ANON__
END

refreport 1  # ~> $s
```

# DESCRIPTION

Telemetry measures the time a program runs between specified points.
Time inside subsegments is not taken into account!

# SUBROUTINES

## refmark (;$mark)

Creates a reference point.

```perl
my $reper1 = refmark "main";

select(undef, undef, undef, .05);

my $reper2 = refmark "reper2";
select(undef, undef, undef, .2);
undef $reper2;

select(undef, undef, undef, .05);

my $reper3 = refmark "reper2";
select(undef, undef, undef, .1);
undef $reper3;

select(undef, undef, undef, .1);

undef $reper1;

# report:
sub round ($) { int($_[0]*10 + .5) / 10 }

my ($report, $total) = refreport;

$total   # -> $report->[0]{interval} + $report->[1]{interval}

scalar @$report     # -> 2
round $total        # -> 0.5

$report->[0]{mark}            # => reper2
$report->[0]{count}           # -> 2
round $report->[0]{interval}  # -> 0.3
round $report->[0]{percent}   # -> 60.0

$report->[1]{mark}            # => main
$report->[1]{count}           # -> 1
round $report->[1]{interval}  # -> 0.2
round $report->[1]{percent}   # -> 40.0
```

## refreport (;$clean)

Make a report on reference points.

Parameter `$clean == 1` clean the report.

```perl
my $s = refreport;
refreport 0  # -> $s
refreport 1  # -> $s

$s = << 'END';
Ref Report -- Total time: 0.000000 mks
   Count          Time  Percent  Interval
----------------------------------------------
END

refreport    # -> $s
```

# SEE ALSO

* `Telemetry::Any`
* `Devel::Timer`

# AUTHOR

Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

Aion::Telemetry is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.
