package Apache::Voodoo;

$VERSION = "3.0200";

use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Apache::Voodoo::Exception;

sub new {
	my $class = shift;
	my $self = {};

	bless $self, $class;

	return $self;
}

sub init { }

################################################################################
# Debugging
################################################################################

sub debug {
	my $self = shift;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->debug(@_);
	}
}

sub info {
	my $self = shift;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->info(@_);
	}
}

sub warn {
	my $self = shift;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->warn(@_);
	}
}

sub error {
	my $self = shift;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->error(@_);
	}
}

sub exception {
	my $self = shift;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->exception(@_);
	}
	Apache::Voodoo::Exception::RunTime::Thrown->throw(join("\n",@_));
}

sub trace {
	my $self = shift;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->trace(@_);
	}
}

sub table {
	my $self = shift;

	if (ref($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->table(@_);
	}
}

sub mark {
	my $self = shift;

	if (defined($Apache::Voodoo::Engine::debug)) {
		$Apache::Voodoo::Engine::debug->mark(Time::HiRes::time, @_);
	}
}

################################################################################
# Behavior control
################################################################################

sub set_view {
	$_[1]->{_view_} = $_[2];
}

sub stop_chain {
	$_[1]->{_stop_chain_} = 1;
}

sub redirect {
	shift;
	Apache::Voodoo::Exception::Application::Redirect->throw(target => shift);
}

sub display_error {
	shift;
	my ($c,$e,$t);
	if (@_ == 3) {
		($c,$e,$t) = @_;
	}
	elsif (@_ >= 2 && $_[0] =~ /^\s*[\w:\.-]+\s*$/) {
		$c = shift;
		$e = shift;
		$t = shift || '/index';
	}
	else {
		$c = '500';
		$e = shift;
		$t = shift || '/index';
	}

	if (ref($t)) {
		Apache::Voodoo::Exception::Application::DisplayError->throw(
			code   => $c,
			error  => $e,
			detail => $t
		);
	}
	else {
		Apache::Voodoo::Exception::Application::DisplayError->throw(
			code   => $c,
			error  => $e,
			target => $t
		);
	}
}

sub access_denied {
	shift;
	my $m = shift || "Access Denied";
	my $t = shift || "/access_denied";

	if (ref($t)) {
		Apache::Voodoo::Exception::Application::AccessDenied->throw(
			error  => $m,
			detail => $t
		);
	}
	else {
		Apache::Voodoo::Exception::Application::AccessDenied->throw(
			error  => $m,
			target => $t
		);
	}
}

sub raw_mode {
	my ($self,$c,$d,$h) = @_;
	Apache::Voodoo::Exception::Application::RawData->throw(
		"content_type" => $c,
		"data"         => $d,
		"headers"      => $h
	);
}

sub history {
	my $self = shift;
	my $session = shift;
	my $index = shift;

	return $session->{'history'}->[$index]->{'uri'}.'?'.$session->{'history'}->[$index]->{'params'};
}

sub tardis {
	my $self = shift;
	my $p = shift;

	my %targets = map { $_ => 1 } @_;

	my $history = $p->{'session'}->{'history'};

	for (my $i=0; $i <= $#{$history}; $i++) {
		if ($targets{$history->[$i]->{'uri'}}) {
			return $self->redirect($self->history($p->{'session'},$i));
		}
	}

	return $self->redirect($self->history($p->{'session'},1));
}

################################################################################
# Text Manipulation
################################################################################

sub mkurlparams {
	my $self = shift;
	my $h    = shift;
	my $o    = shift || {};

	# keep track of what keys out of $o we've used in a non-destructive
	# way to the original structure;
	my %used;

	my @return;
	foreach my $key (keys %{$h}) {
		next if exists($o->{$key});

		# if this key is in $o then we use it's values instead of those in $h
		if (defined($o->{$key})) {
			if (ref($o->{$key})) {
				push(@return, map { "$key=$_" } @{$o->{$key}} );
			}
			else {
				push(@return,"$key=$o->{$key}") if length($o->{$key});
			}

			$used{$key} = 1;
		}
		else {
			if (ref($h->{$key})) {
				push(@return, map { "$key=$_" } @{$h->{$key}} );
			}
			else {
				push(@return,"$key=$h->{$key}") if defined($h->{$key}) && length($h->{$key});
			}
		}
	}

	# append the data in $o
	foreach my $key (keys %{$o}) {
		next if $used{$key}; # this one was used to override the value in $h, skip it

		if (ref($o->{$key})) {
			push(@return, map { "$key=$_" } @{$o->{$key}} );
		}
		else {
			push(@return,"$key=$o->{$key}") if length($o->{$key});
		}
	}

	return join("&amp;",@return);
}

sub prep_select {
	my $self   = shift;
	my $list   = shift;
	my $select = shift;

	unless (ref($select)) {
		$select = [ $select ];
	}
	my %selected = map { $_ => 1 } @{$select};

	return [
		map {
			{
				"ID"              => $_->[0],
				"ID."   . $_->[0] => 1,
				"NAME"            => $_->[1],
				"NAME." . $_->[1] => 1,
				"SELECTED" => (defined $selected{$_->[0]})?'SELECTED':0
			}
		} @{$list}
	];
}

sub safe_text {
	# return $_[1] =~ /^[\w\s\.\,\/\[\]\{\}\+\=\-\(\)\:\;\&\?\*\'\!]*$/;
	return $_[1] =~ /^[\w\s\.\,\/\[\]\{\}\+\=\-\(\)\:\;\&\?\!\*]*$/;
}

sub sanitize_text {
	my $self = shift;
	my $text = shift;

	# return $_[1] =~ /^[\w\s\.\,\/\[\]\{\}\+\=\-\(\)\:\;\&\?\*\'\!]*$/;
	$text =~ s/[^\w\s\.\,\/\[\]\{\}\+\=\-\(\)\:\;\&\?\!\*]/ /g;
	return $text;
}

sub trim {
	my $self  = shift;
	my $param = shift || "";

	$param =~ s/^\s*//o;
	$param =~ s/\s*$//o;

	return $param;
}

################################################################################
# Database Interaction
################################################################################

# deprecated, dbi uses exceptions now.
sub db_error {
	my @caller = caller(1);

	my $query = $DBI::lasth->{'Statement'};
	$query = join("\n", map { $_ =~ s/^\s*//; $_} split(/\n/,$query));

	my $errstr = "\n";
	$errstr .= "==================== DB ERROR ====================\n";
	$errstr .= "TIME:       ". scalar(localtime) . "\n";
	$errstr .= "PACKAGE:    $caller[0]\n";
	$errstr .= "FILE:       $caller[1]\n";
	$errstr .= "SUBROUTINE: $caller[3]\n";
	$errstr .= "LINE:       $caller[2]\n\n";
	$errstr .= "$DBI::errstr\n";
	$errstr .= "===================== QUERY ======================\n";
	$errstr .= "$query\n";
	$errstr .= "==================================================\n";

	# don't really care for this, but there doesn't seem to be any way to
	# terminate this request.
	die $errstr;
}

sub date_to_sql {
	my $self = shift;
	my $date = shift;

	# Get rid of all spaces in the date
	$date =~ s/\s//go;

	# date missing. return null;
	return undef unless (length($date));

	# Split the date up into month day year
	my ($m,$d,$y) = split(/[\/-]/,$date,3);

	# assume two digit years belong in 2000
	if ($y < 1000) { $y += 2000; }

	return sprintf("%04d-%02d-%02d",$y,$m,$d);
}

sub last_insert_id {
	my $self = shift;
	my $dbh  = shift;

	my $res = $dbh->selectall_arrayref("SELECT LAST_INSERT_ID()") || $self->db_error();

	return $res->[0]->[0];
}

# this sub is for use with the callback structure of Apache::Voodoo::Table.
# $params is injected with a arrayref of column to translate
#
# since $params is a reference, the actual columns as seen by the db
# are added to $params and they get back out that way.
# all return values are just error messages (if any)
sub month_year_to_sql {
	my $self = shift;
	my $conn = shift;
	my $params = shift;

	my @errors;

	foreach my $column (@{$params->{'MONTH_YEAR_COLUMNS'}}) {

		# see if the present button was nailed
		if (defined($params->{$column."_present"})) {
			$params->{$column} = '1/1/1000';
		}
		else {
			my $ok = 1;
			if (!defined($params->{$column."_month"})) {
				push(@errors,"MISSING_${column}_month");
				$ok = 0;
			}
			elsif ($params->{$column."_month"} < 1 || $params->{$column."_month"} > 12) {
				push(@errors,"BAD_${column}_month");
				$ok = 0;
			}

			if (!defined($params->{$column."_year"})) {
				push(@errors,"MISSING_${column}_year");
				$ok = 0;
			}
			elsif ($params->{$column."_year"} < 1000 || $params->{$column."_year"} > 9999) {
				push(@errors,"BAD_${column}_year");
				$ok = 0;
			}

			if ($ok == 1) {
				$params->{$column} = $params->{$column."_month"} . "/01/" . $params->{$column."_year"};
			}
		}
	}
	return @errors;
}

sub pretty_mysql_timestamp {
	my $self = shift;
	my $time = shift;

	# make an array out containing every two digits
	my @p = ($time =~ /(\d\d)/go);

	return $self->sql_to_date("$p[0]$p[1]-$p[2]-$p[3]")." ".$self->sql_to_time("$p[4]:$p[5]:$p[6]");
}

sub mysql_timestamp {
	my $self = shift;
	my $time = shift;

	my @p = localtime($time || time);

	$time =~ /^\d+\.(\d+)$/;
	return sprintf("%04d%02d%02d%02d%02d%02d",$p[5]+1900,$p[4]+1,$p[3],$p[2],$p[1],$p[0]);
}

sub sql_to_date {
	my $self = shift;
	my $date = shift;

	if (!defined($date) || $date eq "NULL" || $date =~ /^\s*$/) {
		return "";
	}

	$date =~ s/ .*//go;

	my ($y,$m,$d) = split(/[\/-]/,$date,3);

	return sprintf("%02d/%02d/%04d",$m,$d,$y);
}

sub sql_to_time {
	my $self = shift;
	my $time = shift;

	if (!defined($time) || $time eq "NULL" || $time =~ /^\s*$/) {
		return "";
	}

	$time =~ s/.* //o;

	my ($h,$m,$s) = split(/:/,$time);

	if ($h == 12) {	# noon
		return sprintf("%2d:%02d PM",$h,$m);
	}
	if ($h == 0) {	# midnight
		return sprintf("%2d:%02d AM",12,$m);
	}
	elsif ($h > 12) {
		return sprintf("%2d:%02d PM",$h-12,$m);
	}
	else {
		return sprintf("%2d:%02d AM",$h,$m);
	}
}

sub time_to_sql {
	my $self = shift;
	my $time = shift;

	$time =~ s/\s*//go;
	$time =~ s/\.//go;

	unless ($time =~ /^\d?\d:\d\d(am|pm)?$/io) {
		return undef;
	}

	my $pm = 'NA';
	if ($time =~ s/([ap])m$//igo) {
		$pm = (lc($1) eq "p")?1:0;
	}

	my ($h,$m) = split(/:/,$time,2);

	if ($m < 0 || $m > 60) { return undef; }

	if ($h < 0 || $h > 23) { return undef; }

	# 12 am is midnight and 12 pm is noon...I've always hated that.
	if ($pm eq '1' && $h < 12) {
		$h += 12;
	}
	elsif ($pm eq '0' && $h == 12) {
		$h = 0;
	}

	return sprintf("%02d:%02d:00",$h,$m);
}

################################################################################
# Misc
################################################################################


# Function:  dates_in_order
# Purpose:  Make sure end date comes after start date
sub dates_in_order {
	my $self      = shift;
	my $startdate = shift;
	my $enddate   = shift;

	#split off the parts of the date
	my ($sm,$sd,$sy) = split("/",$startdate, 3);
	my ($em,$ed,$ey) = split("/",$enddate, 3);

	#make sure the end date is past the start date
	if ($ey < $sy) {
		return 0;
	}
	elsif ($ey == $sy) {
		if ($em < $sm) {
			return 0;
		}
		elsif ($em == $sm) {
			if ($ed < $sd) {
				return 0;
			}
		}
	}

	# If we got here we were sucessful
	return 1;
}

# Function: validate_date
# Purpose:  Check to make sure a date follows the MM/DD/YYYY format and checks the sanity of the numbers passed in
sub validate_date {
	my $self = shift;
	my $date = shift;
	my $check_future = shift;

	#Number of days in each month
	my %md = (1  => 31,
	          2  => 29,
	          3  => 31,
	          4  => 30,
	          5  => 31,
	          6  => 30,
	          7  => 31,
	          8  => 31,
	          9  => 30,
	          10 => 31,
	          11 => 30,
	          12 => 31);


	#Split the date up into month day year
	my ($m,$d,$y) = split("/",$date, 3);

	#Strip off any leading 0s
	$m *= 1;
	$d *= 1;
	$y *= 1;

	#If the month isn't within a valid range return
	if ($m !~ /^\d+$/ || $m < 1 || $m > 12) {
		return 0;
	}

	#Check to see if the day is valid on leap years
	if ($m == 2 && $d == 29) {
		unless (($y%4 == 0 && $y%100 != 0) || $y%400 == 0){
			return 0;
		}
	}

	#If the day isn't within a valid range return
	if ($d !~ /^\d+$/ || $d < 1 || $d > $md{$m}) {
		return 0;
	}

	# make sure the year is four digits
	if ($y !~ /^\d+$/ || $y < 1000 || $y > 9999) {
		return 0;
	}

	if ($check_future == 1) {
		#Get the local system time
		my ($M,$D,$Y) = (localtime(time))[4,3,5];
		$M++;
		$Y+=1900;

		#Make sure the date is in the future
		if ($y < $Y) {
			return undef;
		}
		elsif ($y == $Y) {
			if ($m < $M) {
				return undef;
			}
			elsif ($m == $M) {
				if ($d <= $D) {
					return undef;
				}
			}
		}
	}

	# if we make it this far the date should be ok return sucess
	return 1;
}

sub pretty_time {
	my $self = shift;
	my $time = shift;

	my @p = localtime($time || time);

	$time =~ /^\d+\.(\d+)$/;
	my $ms = $1;
	if ($ms) {
		$ms .= '0' x (5-length($ms));

		$ms = " " . $ms;
	}
	return sprintf("%02d/%02d/%04d %02d:%02d:%02d",$p[4]+1, $p[3], $p[5]+1900, $p[2], $p[1], $p[0]) . $ms;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
