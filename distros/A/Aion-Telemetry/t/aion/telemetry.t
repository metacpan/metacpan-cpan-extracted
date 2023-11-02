use common::sense; use open qw/:std :utf8/; use Test::More 0.98; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { use Scalar::Util qw//; use Carp qw//; $SIG{__DIE__} = sub { my ($s) = @_; if(ref $s) { $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s; die $s } else {die Carp::longmess defined($s)? $s: "undef" }}; my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion-telemetry!aion!telemetry/'; `rm -fr '$s'` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; read $__f__, $s, -s $__f__; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# Aion::Telemetry - measures the time the program runs between specified points
# 
# # VERSION
# 
# 0.0.1
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
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

::like scalar do {refreport 1}, qr!$s!, 'refreport 1  # ~> $s';

# 
# # DESCRIPTION
# 
# Telemetry measures the time a program runs between specified points.
# Time inside subsegments is not taken into account!
# 
# # SUBROUTINES
# 
# ## refmark (;$mark)
# 
# Creates a reference point.
# 
done_testing; }; subtest 'refmark (;$mark)' => sub { 
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

::is scalar do {$total}, scalar do{$report->[0]{interval} + $report->[1]{interval}}, '$total   # -> $report->[0]{interval} + $report->[1]{interval}';

::is scalar do {scalar @$report}, scalar do{2}, 'scalar @$report     # -> 2';
::is scalar do {round $total}, scalar do{0.5}, 'round $total        # -> 0.5';

::is scalar do {$report->[0]{mark}}, "reper2", '$report->[0]{mark}            # => reper2';
::is scalar do {$report->[0]{count}}, scalar do{2}, '$report->[0]{count}           # -> 2';
::is scalar do {round $report->[0]{interval}}, scalar do{0.3}, 'round $report->[0]{interval}  # -> 0.3';
::is scalar do {round $report->[0]{percent}}, scalar do{60.0}, 'round $report->[0]{percent}   # -> 60.0';

::is scalar do {$report->[1]{mark}}, "main", '$report->[1]{mark}            # => main';
::is scalar do {$report->[1]{count}}, scalar do{1}, '$report->[1]{count}           # -> 1';
::is scalar do {round $report->[1]{interval}}, scalar do{0.2}, 'round $report->[1]{interval}  # -> 0.2';
::is scalar do {round $report->[1]{percent}}, scalar do{40.0}, 'round $report->[1]{percent}   # -> 40.0';

# 
# ## refreport (;$clean)
# 
# Make a report on reference points.
# 
# Parameter `$clean == 1` clean the report.
# 
done_testing; }; subtest 'refreport (;$clean)' => sub { 
my $s = refreport;
::is scalar do {refreport 0}, scalar do{$s}, 'refreport 0  # -> $s';
::is scalar do {refreport 1}, scalar do{$s}, 'refreport 1  # -> $s';

$s = << 'END';
Ref Report -- Total time: 0.000000 mks
   Count          Time  Percent  Interval
----------------------------------------------
END

::is scalar do {refreport}, scalar do{$s}, 'refreport    # -> $s';

# 
# # SEE ALSO
# 
# * `Telemetry::Any`
# * `Devel::Timer`
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# Aion::Telemetry is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
