package App::Glacier::DateTime;
use strict;
use warnings;
use parent 'DateTime';

use Carp;
use DateTime;

sub new {
    my ($class, @opts) = shift;
    unless (@opts) {
	my ($second, $minute, $hour, $day, $month, $year) = gmtime;
	return $class->SUPER::new(year => 1900 + $year,
				  month => $month + 1,
				  day => $day,
				  hour => $hour,
				  minute => $minute,
				  second => $second);
    }
    return $class->SUPER::new(@_);
}

sub strftime {
    my $self = shift;
    if (@_ > 1) {
	return map { $self->strftime($_) } @_;
    } else {
	my $fmt = shift;
	# DateTime::strftime misinterprets %c. so handle it separately
	$fmt =~ s{(?<!%)%c}
	         {POSIX::strftime('%c',
		                  $self->second,
		                  $self->minute,
		                  $self->hour,
		                  $self->day,
		                  $self->month - 1,
		                  $self->year - 1900,
		                  -1,
		                  -1,
		                  $self->is_dst())}gex;
	if ($fmt !~ /(?<!%)%/) {
	    return $fmt;
	} else {
#	    print "FMT ".$self->year."-".$self->month."-".$self->day."-".$self->hour.';'.$self->minute."\n";
	    return $self->SUPER::strftime($fmt)
	}
    }
}

sub _fmt_default {
    my ($dt) = @_;
    my $now = new App::Glacier::DateTime;
    $dt = $dt->epoch;
    $now = $now->epoch;
    if ($dt < $now && $now - $dt < 6*31*86400) {
	return '%b %d %H:%M';
    } else {	
	return '%b %d  %Y';
    }
}

sub _fmt_iso {
    my ($dt) = @_;
    my $now = new App::Glacier::DateTime;
    $dt = $dt->epoch;
    $now = $now->epoch;
    if ($dt < $now && $now - $dt < 6*31*86400) {
	return '%m-%d %H:%M';
    } else {
	return '%Y-%m-%d';
    }
}

my %format_can = (
    default => \&_fmt_default,
    iso => \&_fmt_iso,
    'long-iso' => '%Y-%m-%d %H:%M',
    'full-iso' => '%Y-%m-%d %H:%M:%S.%N %z',
    'standard' => '%Y-%m-%dT%H:%M:%SZ',
    locale => '%c'
);

sub canned_format {
    my $self = shift;
    my $fmt = shift || 'default';

    if ($fmt =~ /^\+(.+)/) {
	return $self->strftime($1);
    } elsif (exists($format_can{$fmt})) {
	$fmt = $format_can{$fmt};
	$fmt = &{$fmt}($self) if ref($fmt) eq 'CODE';
	return $self->strftime($fmt);
    } else {
	croak "unknown canned format $fmt"
    }
}

sub TO_JSON {
    my $self = shift;
    return $self->canned_format('standard');
}
