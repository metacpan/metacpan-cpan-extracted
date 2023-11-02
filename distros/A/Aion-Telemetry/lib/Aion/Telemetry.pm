package Aion::Telemetry;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.1";

use List::Util qw/sum/;
use Time::HiRes qw//;
use Aion::Format qw/sinterval/;

use Exporter qw/import/;
our @EXPORT = our @EXPORT_OK = qw/refmark refreport/;

# Телеметрия измеряет время, которое работает программа между указанными точками
# Время внутри подотрезков - не учитывается!

# Хеш интервалов: {interval => времени потрачено в сек, count => кол. проходов точки, key => название точки}
my %REFMARK;

# Стек приостановленных точек
my @REFMARKS;

# Последнее время в unixtime.ss
my $REFMARK_LAST_TIME;

# Реперная точка:
#
#   my $mark1 = refmark "mark1";
#   ...
#       # Где-то в подпрограммах:
#   	my $mark2 = refmark "mark2";
#		...
#		undef $mark2;
#   ...
#   undef $mark2;
#
package Aion::Refmark {
	sub DESTROY {
		my $now = Time::HiRes::time();
		my $mark = pop @REFMARKS;
		$mark->{count}++;
		$mark->{interval} += $now - $REFMARK_LAST_TIME;
		$REFMARK_LAST_TIME = $now;
	}
}

sub refmark(;$) {
	my ($mark) = @_ == 0? (caller 1)[3]: @_;

	my $now = Time::HiRes::time();
	$REFMARKS[$#REFMARKS]->{interval} += $now - $REFMARK_LAST_TIME if @REFMARKS;
	$REFMARK_LAST_TIME = $now;

	push @REFMARKS, $REFMARK{$mark} //= {mark => $mark};

	bless \$mark, 'Aion::Refmark'
}

# Создаёт отчёт по реперным точкам
sub refreport(;$) {
	my ($clean) = @_;
	my @v = values %REFMARK;

	%REFMARK = (), undef $REFMARK_LAST_TIME if $clean;

	my $total = sum map $_->{interval}, @v;
	$_->{percent} = ($_->{interval} / $total) * 100 for @v;
	@v = sort {$b->{percent} <=> $a->{percent}} @v;

	return \@v, $total if wantarray;

	join "",
	"Ref Report -- Total time: ${\ sinterval $total }\n",
	sprintf("%8s  %12s  %6s  %s\n", "Count", "Time", "Percent", "Interval"),
	"----------------------------------------------\n",
	map sprintf("%8s  %12s  %6.2f%%  %s\n",
		$_->{count},
		sinterval $_->{interval},
		$_->{percent},
		$_->{mark},
	), @v;
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Telemetry - measures the time the program runs between specified points

=head1 VERSION

0.0.1

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Telemetry measures the time a program runs between specified points.
Time inside subsegments is not taken into account!

=head1 SUBROUTINES

=head2 refmark (;$mark)

Creates a reference point.

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

=head2 refreport (;$clean)

Make a report on reference points.

Parameter C<$clean == 1> clean the report.

	my $s = refreport;
	refreport 0  # -> $s
	refreport 1  # -> $s
	
	$s = << 'END';
	Ref Report -- Total time: 0.000000 mks
	   Count          Time  Percent  Interval
	----------------------------------------------
	END
	
	refreport    # -> $s

=head1 SEE ALSO

=over

=item * C<Telemetry::Any>

=item * C<Devel::Timer>

=back

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

Aion::Telemetry is copyright © 2023 by Yaroslav O. Kosmina. Rusland. All rights reserved.
