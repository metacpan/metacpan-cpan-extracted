=head1 NAME

App::olson - query the Olson timezone database

=head1 SYNOPSIS

    olson list <criterion>... <attribute>...
    olson version

=head1 DESCRIPTION

This module implements the L<olson> command-line utility.  See L<olson>
for details of usage.

=head1 FUNCTIONS

=over

=item App::olson::run(@ARGV)

Performs the job of the L<olson> program.  The interface to this function
may change in the future.

=back

=cut

package App::olson;

{ use 5.006; }
use warnings;
use strict;

use Date::ISO8601 0.000 qw(ymd_to_cjdn present_ymd);
use DateTime::TimeZone::Olson 0.003 qw(
	olson_version olson_all_names olson_canonical_names olson_links
	olson_country_selection olson_tz
);
use DateTime::TimeZone::SystemV 0.002 ();
use DateTime::TimeZone::Tzfile 0.007 ();
use Params::Classify 0.000 qw(is_string);
use Time::OlsonTZ::Data 0.201012 ();
use Time::Unix 1.02 qw(time);

our $VERSION = "0.000";

#
# list utilities
#

sub _all(&@) {
	my $match = shift(@_);
	foreach(@_) {
		return 0 unless $match->($_);
	}
	return 1;
}

#
# exceptions
#

sub _is_exception($) {
	return is_string($_[0]) && $_[0] =~ /\A[!?~]\z/;
}

sub _cmp_exception($$) { $_[0] cmp $_[1] }

#
# calendar dates
#

sub _caltime_offset($$) {
	my($rdns, $offset) = @_;
	return $rdns if _is_exception($rdns);
	return $offset if _is_exception($offset);
	my($rdn, $sod) = @$rdns;
	$sod += $offset;
	use integer;
	my $doff = $sod < 0 ? -((86399-$sod) / 86400) : $sod / 86400;
	$rdn += $doff;
	$sod -= 86400*$doff;
	return [$rdn, $sod];
}

#
# querying timezones
#

my %translate_exception = (
	"zone disuse" => "!",
	"missing data" => "?",
	"offset change" => "~",
);

sub _handle_exception($$$) {
	my($val, $expect_rx, $err) = @_;
	if($err eq "") {
		return $val;
	} elsif($err =~ /\A
		$expect_rx\ in\ the\ [!-~]+\ timezone
		\ due\ to\ (offset\ change|zone\ disuse|missing\ data)\b
	/x) {
		return $translate_exception{$1};
	} else {
		die $err;
	}
}

{
	package App::olson::UtcDateTime;
	sub new {
		my($class, $rdns) = @_;
		return bless({ rdn => $rdns->[0], sod => $rdns->[1] }, $class);
	}
	sub utc_rd_values { ($_[0]->{rdn}, $_[0]->{sod}, 0) }
}

sub _handle_forward_exception($$) {
	return _handle_exception($_[0],
		qr/time [-:TZ0-9]+ is not represented/, $_[1]);
}

{
	package App::olson::LocalDateTime;
	sub new {
		my($class, $rdns) = @_;
		return bless({ rdn => $rdns->[0], sod => $rdns->[1] }, $class);
	}
	sub local_rd_values { ($_[0]->{rdn}, $_[0]->{sod}, 0) }
}

sub _handle_backward_exception($$) {
	return _handle_exception($_[0],
		qr/local time [-:T0-9]+ does not exist/, $_[1]);
}

#
# data type metadata
#

our %type;

$type{string} = {
	desc => "string",
	present => sub { ${$_[0]} },
	present_exception_width => 5,
	cmp => sub { ${$_[0]} cmp ${$_[1]} },
};

$type{zone_name} = {
	desc => "timezone name",
	present => sub { $_[0] },
	present_exception_width => 5,
	present_field_width => 32,
	rx => qr#[\+\-0-9A-Z_a-z]+(?:/[\+\-0-9A-Z_a-z]+)*#,
	parse => sub { $_[0] },
	cmp => sub { $_[0] cmp $_[1] },
};

{ my $areas; sub _areas() { $areas ||= do {
	my %areas;
	foreach my $country (values %{olson_country_selection()}) {
		foreach my $region (values %{$country->{regions}}) {
			$areas{$1} = undef
				if $region->{timezone_name} =~ m#\A([^/]+)/#;
		}
	}
	\%areas;
} } }

$type{area_name} = {
	desc => "area name",
	present => sub { $_[0] },
	present_exception_width => 5,
	present_field_width => 10,
	rx => qr/[A-Za-z]+/,
	parse => sub { ucfirst(lc($_[0])) },
	cmp => sub { $_[0] cmp $_[1] },
};

my $rdn_epoch_cjdn = 1721425;

sub _present_caltime($) {
	my($rdns) = @_;
	my($rdn, $sod) = @$rdns;
	use integer;
	return present_ymd($rdn + $rdn_epoch_cjdn).
		"T".sprintf("%02d:%02d:%02d", $sod/3600, $sod/60%60, $sod%60);
}

my $caltime_rx = qr/
	[0-9]{4}
	(?:-[0-9]{2}
	(?:-[0-9]{2}
	(?:(?:\ +|\ *[Tt]\ *)[0-9]{2}
	(?::[0-9]{2}
	(?::[0-9]{2}
	)?)?)?)?)?
	|
	[0-9]{4}
	(?:[0-9]{2}
	(?:[0-9]{2}
	(?:\ *(?:[Tt]\ *)?[0-9]{2}
	(?:[0-9]{2}
	(?:[0-9]{2}
	)?)?)?)?)?
/x;

sub _parse_caltime($) {
	my($txt) = @_;
	my($y, $mo, $d, $h, $mi, $s) = ($txt =~ /\A
		([0-9]{4})
		(?:.*?([0-9]{2})
		(?:.*?([0-9]{2})
		(?:.*?([0-9]{2})
		(?:.*?([0-9]{2})
		(?:.*?([0-9]{2})
		)?)?)?)?)?
	/sx);
	$mo = "01" unless defined $mo;
	$d = "01" unless defined $d;
	my $rdn = eval {
		local $SIG{__DIE__};
		ymd_to_cjdn($y, $mo, $d) - $rdn_epoch_cjdn;
	};
	if($@ ne "") {
		my $err = $@;
		$err =~ s/ at .*\z/\n/s;
		die $err;
	}
	$h = "00" unless defined $h;
	$mi = "00" unless defined $mi;
	$s = "00" unless defined $s;
	die "hour number $h is out of the range [0, 24)\n" unless $h < 24;
	die "minute number $mi is out of the range [0, 60)\n" unless $mi < 60;
	die "second number $s is out of the range [0, 60)\n" unless $s < 60;
	return [ $rdn, 3600*$h + 60*$mi + $s ];
}

$type{calendar_time} = {
	desc => "calendar time",
	present => \&_present_caltime,
	present_exception_width => 19,
	rx => $caltime_rx,
	parse => \&_parse_caltime,
	cmp => sub { $_[0]->[0] <=> $_[1]->[0] || $_[0]->[1] <=> $_[1]->[1] },
};

my $unix_epoch_rdn = 719163;

my $now_absolute_time;
sub _now_absolute_time() {
	return $now_absolute_time ||= do {
		my $nowu = time;
		[ int($nowu/86400) + $unix_epoch_rdn, $nowu % 86400 ];
	};
}

$type{absolute_time} = {
	desc => "absolute time",
	present => sub { _present_caltime($_[0])."Z" },
	present_exception_width => 20,
	rx => qr/(?:(?:$caltime_rx) *[Zz]|now)/o,
	parse => sub {
		if($_[0] eq "now") {
			return _now_absolute_time();
		} else {
			return _parse_caltime($_[0]);
		}
	},
	cmp => $type{calendar_time}->{cmp},
};

$type{country_code} = {
	desc => "country code",
	present => sub { $_[0] },
	present_exception_width => 2,
	rx => qr/[A-Za-z]{2}/,
	parse => sub { uc($_[0]) },
	cmp => sub { $_[0] cmp $_[1] },
};

$type{initialism} = {
	desc => "initialism",
	present => sub { $_[0] },
	present_exception_width => 3,
	present_field_width => 6,
	rx => qr/[\+\-0-9A-Za-z]{3,}/,
	parse => sub { $_[0] },
	cmp => sub { $_[0] cmp $_[1] },
};

$type{offset} = {
	desc => "offset",
	present => sub {
		my($offset) = @_;
		my $sign = $offset < 0 ? "-" : "+";
		$offset = abs($offset);
		use integer;
		my $disp = sprintf("%s%02d:%02d:%02d", $sign,
				$offset/3600, $offset/60%60, $offset%60);
		$disp =~ s/(?::00)+\z//;
		return $disp;
	},
	present_exception_width => 3,
	present_field_width => 9,
	rx => qr/[-+][0-9]{2}
		(?:[0-9]{2}(?:[0-9]{2})?|:[0-9]{2}(?::[0-9]{2})?)?
	/x,
	parse => sub {
		my($txt) = @_;
		my($sign, $h, $m, $s) = ($txt =~ /\A
			([-+])
			([0-9]{2})
			(?:.*?([0-9]{2})
			(?:.*?([0-9]{2})
			)?)?
		/sx);
		$m = 0 unless defined $m;
		$s = 0 unless defined $s;
		die "minute number $m is out of the range [0, 60)\n"
			unless $m < 60;
		die "second number $s is out of the range [0, 60)\n"
			unless $s < 60;
		return (3600*$h + 60*$m + $s) * ($sign eq "-" ? -1 : +1);
	},
	cmp => sub { $_[0] <=> $_[1] },
};

$type{truth} = {
	desc => "truth value",
	present => sub { $_[0] ? "+" : "-" },
	rx => qr/[-+]/,
	parse => sub { $_[0] eq "+" ? 1 : 0 },
	cmp => sub { $_[0] <=> $_[1] },
};

sub _type_parse_from_gmatch($$) {
	my($type, $rtxt) = @_;
	my $typerx = $type->{rx} or die "can't input a @{[$type->{desc}]}\n";
	$$rtxt =~ /\G(
		[\+\-\/0-9\:A-Z_a-z]
		(?:[\ \+\-\/0-9\:A-Z_a-z]*[\+\-\/0-9\:A-Z_a-z])?
	)/xgc or die "missing value\n";
	my $valtxt = $1;
	$valtxt =~ /\A$typerx\z/ or die "malformed @{[$type->{desc}]}\n";
	return $type->{parse}->($valtxt);
}

sub _type_curry_xpresent($) {
	my($type) = @_;
	my $pew = exists($type->{present_exception_width}) ?
			$type->{present_exception_width} : 1;
	my $pfw = exists($type->{present_field_width}) ?
			$type->{present_field_width} : 0;
	return $type->{t_present} ||= sub {
		my($value) = @_;
		my $txt = _is_exception($value) ?
				$value x $pew : $type->{present}->($value);
		$txt .= " " x ($pfw - length($txt)) if $pfw > length($txt);
		return $txt;
	};
}

sub _type_curry_xcmp($) {
	my($type) = @_;
	my $cmp_normal = $type->{cmp};
	return $type->{t_cmp} ||= sub {
		my($x, $y) = @_;
		if(_is_exception($x)) {
			if(_is_exception($y)) {
				return _cmp_exception($x, $y);
			} else {
				return -1;
			}
		} else {
			if(_is_exception($y)) {
				return +1;
			} else {
				return $cmp_normal->($x, $y);
			}
		}
	};
}

#
# timezone attribute classes
#

our %attrclass;

$attrclass{z} = $attrclass{zone_name} = {
	desc => "timezone name",
	params => {},
	type => "zone_name",
	check_value => sub {
		die "no such timezone `$_[0]'\n"
			unless exists olson_all_names()->{$_[0]};
	},
	cost => 0,
	get_needs => { z=>undef },
	curry_get => sub { sub { $_[0]->{z} } },
};

$attrclass{a} = $attrclass{area_name} = {
	desc => "area name",
	params => {},
	type => "area_name",
	check_value => sub {
		die "no such area `$_[0]'\n" unless exists _areas()->{$_[0]};
	},
	cost => 1,
	get_needs => { z=>undef },
	curry_get => sub {
		my $areas = join("|", map { "\Q$_\E" } keys %{_areas()});
		my $arearx = qr#\A($areas)/#o;
		return sub { $_[0]->{z} =~ $arearx ? "$1" : "!" };
	},
};

$attrclass{c} = $attrclass{country_code} = {
	desc => "country code",
	params => {},
	type => "country_code",
	check_value => sub {
		die "no such country code `$_[0]'\n"
			unless exists olson_country_selection()->{$_[0]};
	},
	cost => 0,
	get_needs => { c=>undef },
	curry_get => sub { sub { $_[0]->{c} } },
};

$attrclass{cn} = $attrclass{country_name} = {
	desc => "country name",
	params => {},
	type => "string",
	cost => 1,
	get_needs => { c=>undef },
	curry_get => sub {
		my $sel = olson_country_selection();
		return sub { \$sel->{$_[0]->{c}}->{olson_name} };
	},
};

$attrclass{rd} = $attrclass{region_description} = {
	desc => "region description",
	params => {},
	type => "string",
	cost => 1,
	get_needs => { region=>undef },
	curry_get => sub { sub { \$_[0]->{region}->{olson_description} } },
};

$attrclass{k} = $attrclass{canonical_zone_name} = {
	desc => "canonical timezone name",
	params => {},
	type => "zone_name",
	check_value => sub {
		die "no such canonical timezone `$_[0]'\n"
			unless exists olson_canonical_names()->{$_[0]};
	},
	cost => 1,
	get_needs => { z=>undef },
	curry_get => sub {
		my $links = olson_links();
		return sub {
			my $z = $_[0]->{z};
			return exists($links->{$z}) ? $links->{$z} : $z;
		};
	},
};

$attrclass{o} = $attrclass{offset} = {
	desc => "offset",
	params => { "\@" => "absolute_time" },
	type => "offset",
	cost => 10,
	get_needs => { z=>undef },
	curry_get => sub {
		my($when) = $_[0]->{"\@"};
		my $whendt = App::olson::UtcDateTime->new($when);
		return sub {
			my $zone = olson_tz($_[0]->{z});
			return _handle_forward_exception(eval {
				local $SIG{__DIE__};
				0+$zone->offset_for_datetime($whendt);
			}, $@);
		};
	},
};

$attrclass{i} = $attrclass{initialism} = {
	desc => "initialism",
	params => { "\@" => "absolute_time" },
	type => "initialism",
	cost => 10,
	get_needs => { z=>undef },
	curry_get => sub {
		my($when) = $_[0]->{"\@"};
		my $whendt = App::olson::UtcDateTime->new($when);
		return sub {
			my $zone = olson_tz($_[0]->{z});
			return _handle_forward_exception(eval {
				local $SIG{__DIE__};
				$zone->short_name_for_datetime($whendt);
			}, $@);
		};
	},
};

$attrclass{d} = $attrclass{dst_status} = {
	desc => "DST status",
	params => { "\@" => "absolute_time" },
	type => "truth",
	cost => 10,
	get_needs => { z=>undef },
	curry_get => sub {
		my($when) = $_[0]->{"\@"};
		my $whendt = App::olson::UtcDateTime->new($when);
		return sub {
			my $zone = olson_tz($_[0]->{z});
			return _handle_forward_exception(eval {
				local $SIG{__DIE__};
				$zone->is_dst_for_datetime($whendt) ? 1 : 0;
			}, $@);
		};
	},
};

$attrclass{t} = $attrclass{local_time} = {
	desc => "local time",
	params => { "\@" => "absolute_time" },
	type => "calendar_time",
	cost => 11,
	get_needs => { z=>undef },
	curry_get => sub {
		my($when) = $_[0]->{"\@"};
		my $get_offs = $attrclass{offset}->{curry_get}->($_[0]);
		return sub { _caltime_offset($when, $get_offs->($_[0])) };
	},
};

sub _parse_attribute_from_gmatch($) {
	my($rtxt) = @_;
	$$rtxt =~ /\G([a-zA-Z0-9_]+)/gc or die "missing attribute name\n";
	my $classname = $1;
	my $ac = $attrclass{$classname}
		or die "no such attribute class `$classname'\n";
	my %pval;
	while($$rtxt =~ /\G *([\@]) */gc) {
		my $pkey = $1;
		die "clashing `$pkey' parameters for ".
			"@{[$ac->{desc}]} attribute\n"
				if exists $pval{$pkey};
		my $ptype = $ac->{params}->{$pkey}
			or die "unwanted `$pkey' parameter for ".
				"@{[$ac->{desc}]} attribute\n";
		$pval{$pkey} = _type_parse_from_gmatch($type{$ptype}, $rtxt);
	}
	foreach my $pkey (keys %{$ac->{params}}) {
		die "@{[$ac->{desc}]} attribute needs a `$pkey' parameter\n"
			unless exists $pval{$pkey};
	}
	my $get = $ac->{curry_get}->(\%pval);
	return {
		type => $type{$ac->{type}},
		check_value => $ac->{check_value} || sub { },
		cost => $ac->{cost},
		get_needs => $ac->{get_needs},
		xget => sub {
			foreach(keys %{$ac->{get_needs}}) {
				return "!" unless exists $_[0]->{$_};
			}
			return &$get;
		},
	};
}

my %cmp_ok = (
	"<" => sub { $_[0] < 0 },
	">" => sub { $_[0] > 0 },
	"<=" => sub { $_[0] <= 0 },
	">=" => sub { $_[0] >= 0 },
	"=" => sub { $_[0] == 0 },
);

sub _parse_criterion_from_gmatch($) {
	my($rtxt) = @_;
	my $attr = _parse_attribute_from_gmatch($rtxt);
	$$rtxt =~ /\G *(!)?([<>]=?|=|\?)/gc
		or die "syntax error in criterion\n";
	my($neg, $op) = ($1, $2);
	my $get = $attr->{xget};
	my $posxmatch;
	if($op eq "?") {
		$posxmatch = sub { !_is_exception(&$get) };
	} else {
		my $cmpok = $cmp_ok{$op};
		$$rtxt =~ /\G +/gc;
		my $cmpval = _type_parse_from_gmatch($attr->{type}, $rtxt);
		$attr->{check_value}->($cmpval);
		my $cmp = $attr->{type}->{cmp};
		$posxmatch = sub {
			my $val = &$get;
			return 0 if _is_exception($val);
			return $cmpok->($cmp->($val, $cmpval));
		};
	}
	return {
		cost => $attr->{cost},
		match_needs => $attr->{get_needs},
		xmatch => $neg ? sub { !&$posxmatch } : $posxmatch,
	};
}

#
# top-level commands
#

my %command;

$command{version} = sub {
	die "bad arguments\n" if @_;
	print "modules:\n";
	foreach my $mod (qw(
		App::olson
		DateTime::TimeZone::Olson
		DateTime::TimeZone::SystemV
		DateTime::TimeZone::Tzfile
		Time::OlsonTZ::Data
	)) {
		no strict "refs";
		print "    $mod ${qq(${mod}::VERSION)}\n";
	}
	print "Olson database: @{[olson_version]}\n";
};

$command{list} = sub {
	my(@criteria, @output_attrs, @display_attrs, @sort_attrs);
	foreach my $arg (@_) {
		if($arg =~ /\A *[-+]/) {
			pos($arg) = undef;
			$arg =~ /\G *([-+]) */gc;
			my $neg = $1 eq "-";
			my $attr = _parse_attribute_from_gmatch(\$arg);
			$arg =~ /\G *\z/gc
				or die "syntax error in sort directive\n";
			push @output_attrs, $attr;
			push @sort_attrs, { index=>$#output_attrs, neg=>$neg };
			next;
		}
		if($arg =~ /\A *[0-9A-Z_a-z]/) {
			pos($arg) = undef;
			$arg =~ /\G +/gc;
			my $attr = _parse_attribute_from_gmatch(\$arg);
			if($arg =~ /\G *\z/gc) {
				push @output_attrs, $attr;
				push @display_attrs, $#output_attrs;
				next;
			}
		}
		pos($arg) = undef;
		$arg =~ /\G +/gc;
		my $crit = _parse_criterion_from_gmatch(\$arg);
		$arg =~ /\G *\z/gc or die "syntax error in criterion\n";
		push @criteria, $crit;
	}
	die "must list at least one attribute\n" unless @display_attrs;
	push @sort_attrs, map { { index=>$_, neg=>0 } } @display_attrs;
	@criteria = sort { $a->{cost} <=> $b->{cost} } @criteria;
	my %need = (
		(map { %{$_->{match_needs}} } @criteria),
		(map { %{$_->{get_needs}} } @output_attrs),
	);
	my @joined;
	if(exists($need{region}) || exists($need{c})) {
		# Fully joining zones, regions, and countries is pretty
		# cheap, so don't try to be cleverer about doing less
		# join work.
		my %zleft = %{olson_all_names()};
		my $sel = olson_country_selection();
		foreach(sort keys %$sel) {
			my $csel = $sel->{$_};
			if(keys(%{$csel->{regions}}) == 0) {
				push @joined, { c => $csel->{alpha2_code} };
				next;
			}
			foreach(sort keys %{$csel->{regions}}) {
				my $reg = $csel->{regions}->{$_};
				my $zname = $reg->{timezone_name};
				push @joined, {
					c => $csel->{alpha2_code},
					region => $reg,
					z => $zname,
				};
				delete $zleft{$zname};
			}
		}
		push @joined, {z=>$_} foreach sort keys %zleft;
	} else {
		@joined = map { {z=>$_} } sort keys %{olson_all_names()};
	}
	my @presenters =
		map { _type_curry_xpresent($_->{type}) } @output_attrs;
	my @sorters = map { _type_curry_xcmp($_->{type}) } @output_attrs;
	my %output;
	foreach my $item (@joined) {
		next unless _all { $_->{xmatch}->($item) } @criteria;
		my @vals = map { $_->{xget}->($item) } @output_attrs;
		next if _all { _is_exception($_) && $_ eq "!" } @vals;
		$output{
			join("\0", map { $presenters[$_]->($vals[$_]) }
					0..$#output_attrs)
		} = \@vals;
	}
	foreach(sort {
		my $av = $output{$a};
		my $bv = $output{$b};
		my $res = 0;
		foreach(@sort_attrs) {
			$res = $sorters[$_->{index}]
				->($av->[$_->{index}], $bv->[$_->{index}]);
			$res = -$res if $_->{neg};
			last if $res != 0;
		}
		$res;
	} keys %output) {
		my $vals = $output{$_};
		my $line = join("  ", map { $presenters[$_]->($vals->[$_]) }
					@display_attrs);
		$line =~ s/ +\z//;
		print $line, "\n";
	}
};

sub run(@) {
	my $cmd = shift(@_);
	defined $cmd or die "no subcommand specified\n";
	($command{$cmd} || sub { die "unrecognised subcommand\n" })->(@_);
}

=head1 SEE ALSO

L<DateTime::TimeZone::Olson>,
L<Time::OlsonTZ::Data>,
L<olson>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2012 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
