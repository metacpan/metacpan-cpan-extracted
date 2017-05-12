package DBD::PgLite;

### DBI related package globals:
our $drh;                  # Driver handle
our $err = 0;	           # Holds error code for $DBI::err.
our $errstr = '';	       # Holds error string for $DBI::errstr.
our $sqlstate = '';	       # Holds SQL state for $DBI::state.
our $imp_data_size = 0;    # required by DBI
our $VERSION = '0.11';

### Modules
use strict;
use DBD::SQLite;

use Time::HiRes ();
use Time::Local;
use POSIX qw( LC_CTYPE LC_COLLATE );
my $locale = $ENV{LC_COLLATE} || $ENV{LC_ALL} || $ENV{LANG} || $ENV{LC_CTYPE} || 'C';
POSIX::setlocale( LC_CTYPE, $locale );
POSIX::setlocale( LC_COLLATE, $locale );
use locale;
use Math::Trig ();
use Text::Iconv;
use MIME::Base64 ();
use Digest::MD5 ();

# Instance variables, accessible through
#   setTime, getTime, setTransaction, getTransaction,
{
  my $Time;
  my $Transaction;
  my $Dbh;
  my $Currval = {};
  my $LastvalSeq;
  sub Time {
	  $Time = shift if @_;
	  $Time ||= Time::HiRes::time;
	  return $Time;
  }
  sub Transaction {
	  $Transaction = shift if @_;
	  $Transaction = 0 unless defined $Transaction;
	  return $Transaction;
  }
  sub Dbh {
	  $Dbh = shift if @_;
	  return $Dbh;
  }
  sub Currval {
	  my ($sn,$set) = @_;
	  $sn = lc($sn);
	  $Currval->{$sn} = int($set) if $set;
	  return $Currval->{$sn};
  }
  sub Lastval {
	  $LastvalSeq = lc(shift) if @_;
	  return $Currval->{$LastvalSeq};
  }
}
sub setTime { Time(Time::HiRes::time); }
sub getTime { Time(); }
sub setTransaction { Transaction(shift); }
sub getTransaction { Transaction(); }
sub setDbh { Dbh(shift); }
sub getDbh { Dbh(); }
sub getCurrval { Currval(shift); }
sub setCurrval { Currval(@_); }
sub getLastval { Lastval(); }
sub setLastval { Lastval(shift); }

### Main package methods/subs ######

sub driver {
	return $drh if ($drh);
	my ($class, $attr) = @_;
	$class .= "::dr";
	($drh) = DBI::_new_drh ($class, {
		'Name' => 'PgLite',
		'Version' => $VERSION,
		'Attribution' => 'DBD::PgLite by Baldur Kristinsson',
	});
	return $drh;
}

sub disconnect_all { } # required by DBI
sub DESTROY {
	my $dbh = getDbh();
	$dbh->disconnect if $dbh;
}


# Localeorder function legwork

my (@chars,%chars);
for (1..254) {
	push @chars, chr($_);
}
@chars = sort { lc($a) cmp lc($b) } @chars;
%chars = map { ($chars[$_] => sprintf("%x",$_)) } 0..$#chars;
my $localeorder_func = sub {
	my $str = shift;
	return join('', map { $chars{$_} } split //, $str);
};

# Make sure sequence environment is sane and yield a
# database handle to sequence functions
sub _seq_init {
	my $sn = lc(shift);
	my $dbh = getDbh();
	# Create sequence table if it does not exist
	my $check_tbl = "select name from sqlite_master where name = ? and type = 'table'";
	unless ($dbh->selectrow_array($check_tbl, {}, 'pglite_seq')) {
		$dbh->do("create table pglite_seq (sequence_name text primary key, last_value int, is_locked int, is_called int)");
	}
	my $check_seq = "select sequence_name from pglite_seq where sequence_name = ?";
	# Autocreate sequence if it does not exist
	unless ($dbh->selectrow_array($check_seq,{},$sn)) {
		$dbh->do("insert into pglite_seq (sequence_name, last_value, is_locked, is_called) values (?,?,?,?)",
				 {}, $sn, 1, 1, 0);
		# Find a matching table, if possible, and set last_value based on that
		my $tn = $sn;
		$tn =~ s/_seq$//;
		my ($val,$col) = (0,'');
		while (!$val && $tn=~/_+[a-z]*$/) {
			$col = ($col ? "${1}_$col" : $1) if $tn =~ s/_+([a-z]*)$//;
			if ($dbh->selectrow_array($check_tbl, {}, $tn)) {
				eval {
					$val = $dbh->selectrow_array("select max($col) from $tn");
				};
			}
		}
		if (int($val) > 0) {
			$dbh->do("update pglite_seq set last_value = ?, is_called = 1 where sequence_name = ?",
					 {}, int($val), $sn);
		}
		# unlock sequence before we continue
		$dbh->do("update pglite_seq set is_locked = 0 where sequence_name = ?",{},$sn);
	}
	return $dbh;
}


# Advance the sequence object to its next value and return that
# value.
sub _nextval {
	my $sn = lc(shift);
	my $dbh = _seq_init($sn);
	my $tries;
	while (1) {
		my $rc = $dbh->do("update pglite_seq set last_value = last_value + 1, is_locked = 1 where sequence_name = ? and is_locked = 0 and is_called = 1",{},$sn);
		last if $rc && $rc > 0;
		$rc = $dbh->do("update pglite_seq set is_locked = 1 where sequence_name = ? and is_locked = 0 and is_called = 0",{},$sn);
		last if $rc && $rc > 0;
		Time::HiRes::sleep(0.05);
		die "Too many tries trying to update sequence '$sn' - need manual fix?" if ++$tries > 20;
	}
	my $sval = $dbh->selectrow_array("select last_value from pglite_seq where sequence_name = ?",{},$sn);
	$dbh->do("update pglite_seq set is_locked = 0, is_called = 1 where sequence_name = ? and is_locked = 1",{},$sn);
	setLastval($sn);
	setCurrval($sn,$sval);
	return $sval;
}

# Return the value most recently obtained by nextval for this sequence
# in the current session.
sub _currval {
	my $sn = lc(shift);
	my $val = getCurrval($sn);
	die qq[ERROR: currval of sequence "$sn" is not yet defined in this session] unless $val;
	return $val;
}


# Return the value most recently returned by nextval in the current
# session.
sub _lastval {
	my $val = getLastval();
	die qq[ERROR: lastval is not yet defined in this session] unless $val;
	return $val;
}


# Reset the sequence object's counter value.
sub _setval {
	my ($sn,$val,$called) = @_;
	$sn = lc($sn);
	$val = int($val);
	die "ERROR: Value of sequence '$sn' must be a positive integer" unless $val;
	$called = 1 unless defined($called);
	$called = $called ? 1 : 0;
	my $dbh = _seq_init($sn);
	my $tries;
	while (1) {
		my $rc = $dbh->do("update pglite_seq set last_value = ?, is_called = ? where sequence_name = ? and is_locked = 0",
						  {}, $val, $called, $sn);
		last if $rc && $rc > 0;
		Time::HiRes::sleep(0.05);
		die "Too many tries trying to update sequence '$sn' - need manual fix?" if ++$tries > 20;
	}
	return $val;
}


# Utility functions for succinct expression below

sub _trim {
	my ($mode,$str,$chars) = @_;
	$mode ||= 'both';
	$chars ||= " \n\t\r";
	my ($left,$right);
	$left = $mode =~ /both|leading|left/i ? 1 : 0;
	$right = $mode =~ /both|trailing|right/i ? 1 : 0;
	$chars = "[".quotemeta($chars)."]+";
	$str =~ s/^$chars// if $left;
	$str =~ s/$chars$// if $right;
	return $str;
}

my %_encode = ( 'base64' => sub { my $x = MIME::Base64::encode_base64(shift); chomp $x; return $x; },
				'hex'    => sub { unpack("H*",shift) },
				'escape' => sub { $_[0]=~s/\0/\\000/g; return $_[0]; }, );
my %_decode = ( 'base64' => sub { MIME::Base64::decode_base64(shift) },
				'hex'    => sub { pack("H*",shift) },
				'escape' => sub { $_[0]=~s/\\000/\0/g; return $_[0]; }, );

sub _convert {
	my ($txt,$from,$to) = @_;
	return $txt unless $txt;
	return $txt if $from eq $to;
	my $c = Text::Iconv->new($from,$to) or die "No conversion possible: $from -> $to\n";
	$txt = $c->convert($txt) or die "Could not convert $from -> $to";
	return $txt;
}

# Guess what Latin-1 is called in the iconv() implementation of this OS
sub _latin1_symbol {
	my ($kernel) = POSIX::uname();
	return '8859-1' if $kernel =~ /SunOS|Solaris/i;
	return 'ISO-8859-1';
}

sub _pad {
	my ($mode,$str,$len,$fill) = @_;
	$fill ||= ' ';
	return substr($str,0,$len) if length($str)>=$len;
	if ($mode eq 'left') {
		my $addlen = $len - length($str);
		$fill = $fill x $addlen;
		$fill = substr($fill,0,$addlen);
		$str = "$fill$str";
	}
	else {
		while (length($str) < $len) {
			$str .= $fill;
		}
	}
	$str = substr($str,0,$len);
	return $str;
}

sub _to_ascii {
	my ($str,$encoding) = @_;
	$str = _convert($str,$encoding,_latin1_symbol()) if $encoding;
	$str =~ tr[àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞ]
	          [aaaaaaaceeeeiiiidnoooooouuuuytAAAAAAACEEEEIIIIDNOOOOOOUUUUYT];
	return $str;
}

sub _pgtime_to_time {
	my $pgt = shift;
	return $pgt if $pgt !~ /-/;
	$pgt =~ s/\+\d+$//; # ignore timezone
	my ($yr,$mon,$day, $hr,$min,$sec, $fraction) = (0,0,0, 0,0,0, 0);
	if ($pgt=~/^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)\.(\d+)$/) {
		($yr,$mon,$day,$hr,$min,$sec,$fraction) = ($1,$2,$3, $4,$5,$6, $7);
	} elsif ($pgt=~/^(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)$/) {
		($yr,$mon,$day,$hr,$min,$sec) = ($1,$2,$3, $4,$5,$6);
	} elsif ($pgt=~/^(\d+)-(\d+)-(\d+) (\d+):(\d+)$/) {
		($yr,$mon,$day,$hr,$min) = ($1,$2,$3, $4,$5);
	} elsif ($pgt=~/^(\d+)-(\d+)-(\d+)$/) {
		($yr,$mon,$day) = ($1,$2,$3);
	}
	die "Invalid date/time format in '$pgt'" unless $yr;
	my $t = timelocal($sec,$min,$hr,$day,$mon-1,$yr);
	if ($fraction) {
		$fraction = '0.'.$fraction;
		$t += $fraction;
	}
	return $t;
}

sub _to_char {
	my ($time,$format) = @_;
	my %h = _time_to_hash($time,'to_char');
	my @hk = sort { length($b)<=>length($a) || $b cmp $a } keys %h;
	for (@hk) {
		$format =~ s{$_}{$h{$_}}g;
	}
	$format =~ s/da[Ýý]/day/g;
	$format =~ s/DAÝ/DAY/g;
	return $format;
}

sub _extract {
	my ($field,$time) = @_;
	my %h = _time_to_hash($time,'extract');
	return $h{lc($field)};
}

sub _date_trunc {
	my ($field,$time) = @_;
	$time = _pg_current('timestamp',0,$time) if $time =~ /^\d+$/;
	$time =~ s/\+00$//;
	if ($field eq 'second') {
		$time =~ s/\.\d+$//;
	} elsif ($field eq 'minute') {
		$time =~ s/:\d\d\.\d+$/:00/;
	} elsif ($field eq 'hour') {
		$time =~ s/:\d\d:\d\d\.\d+$/:00:00/;
	} elsif ($field eq 'day') {
		$time =~ s/ \d\d:\d\d:\d\d\.\d+$/ 00:00:00/;
	} elsif ($field eq 'month') {
		$time =~ s/-\d\d \d\d:\d\d:\d\d\.\d+$/-01 00:00:00/;
	} elsif ($field eq 'year') {
		$time =~ s/-\d\d-\d\d \d\d:\d\d:\d\d\.\d+$/-01-01 00:00:00/;
	} else {
		die "Unknown or unimplemented field name: $field";
	}
}

my @month = qw(January February March April May June July August September October November December);
my @wday = qw(SundaÝ MondaÝ TuesdaÝ WednesdaÝ ThursdaÝ FridaÝ SaturdaÝ); # prevent recursion
my @roman = qw(i ii iii iv v vi vii viii ix x xi xii);
sub _time_to_hash {
	my $t = shift;
	my $type = shift;
	my ($sec,$min,$hr,$day,$mon,$yr,$wday,$yday,$isdst) = localtime($t);
	my $leap = $yr % 4 ? 0 : 1; # need only approximation because of restricted range (1970-2038)
	my $ystart_dow = (localtime $t-$yday*60*60*24)[6];
	my @iwn_offset = qw(1 7 6 5 4 3 2); # iso week number offset for dow
	my @mdays = qw(31 28 31 30 31 30 31 31 30 31 30 31);
	$mdays[1] += $leap;
	my $ylen = 365+1;
	my $fraction = $t;
	$fraction =~ s/^\d+\./0\./; $fraction=0 if $fraction>=1;
	my $ampm = $hr > 11 ? 'p.m.' : 'a.m.';
	my $ampm_short = $hr > 11 ? 'pm' : 'am';
	my %h;
	if ($type eq 'extract') {
		# extract: missing timezone*
		%h = (
			  day    => $day,
			  dow    => $wday,
			  doy    => $yday+1,
			  epoch  => $t,
			  hour   => $hr,
			  minute => $min,
			  month  => $mon+1,
			  second => $sec + $fraction,
			  year   => $yr+1900,
			  century=> substr($yr+1900,0,2),
			  decade => substr($yr+1900,0,3),
			  week   => int(($yday+$iwn_offset[$ystart_dow])/7+.9),
			  quarter=> int(((($mon+1)/12)*4)+0.8),
			  microseconds=> ($fraction+$sec)*1_000_000,
			  milliseconds => ($fraction+$sec)*1_000,
			  millennium=> $yr>100 ? 3 : 2, # restricted range (1970-2038)
			 );
	} else {
		# to_char: missing: 'Y,YYY', IYYY,, IYY, IY, I, J, TZ, tz
		# FM prefix supported for HH*, MM and DD but not otherwise.
		# Other formatting prefixes not supported.
		%h = (
			  HH     => sprintf("%02d", $hr==12 ? $hr : $hr%12),
			  HH12   => sprintf("%02d", $hr==12 ? $hr : $hr%12),
			  HH24   => sprintf("%02d", $hr),
			  FMHH   => sprintf("%d", $hr==12 ? $hr : $hr%12),
			  FMHH12 => sprintf("%d", $hr==12 ? $hr : $hr%12),
			  FMHH24 => sprintf("%d", $hr),
			  MI     => sprintf("%02d", $min),
			  SS     => sprintf("%02d", $sec),
			  MS     => substr(sprintf("%.3f",$fraction),2,3),
			  US     => substr(sprintf("%.6f",$fraction),2,6),
			  DD     => sprintf("%02d", $day),
			  D      => $wday+1,
			  DDD    => $yday+1,
			  FMDD   => sprintf("%d", $day),
			  MM     => sprintf("%02d", $mon+1),
			  FMMM   => sprintf("%d", $mon+1),
			  YYYY   => sprintf("%d", $yr+1900),
			  YYY    => sprintf("%03d", ($yr+1900)%1000),
			  YY     => sprintf("%02d", ($yr+1900)%100),
			  Y      => sprintf("%d", $yr%10),
			  am     => $ampm_short,
			  'a.m.' => $ampm,
			  pm     => $ampm_short,
			  'p.m.' => $ampm,
			  AM     => uc($ampm_short),
			  'A.M.' => uc($ampm),
			  PM     => uc($ampm_short),
			  'P.M.' => uc($ampm),
			  SSSS   => $sec + 60*$min + 3600*$hr,
			  MONTH  => sprintf("%-9s",uc($month[$mon])),
			  MON    => uc(substr($month[$mon],0,3)),
			  month  => sprintf("%-9s",lc($month[$mon])),
			  mon    => lc(substr($month[$mon],0,3)),
			  Month  => sprintf("%-9s",$month[$mon]),
			  Mon    => substr($month[$mon],0,3),
			  DAY    => sprintf("%-9s",uc($wday[$wday])),
			  DY     => uc(substr($wday[$wday],0,3)),
			  day    => sprintf("%-9s",lc($wday[$wday])),
			  dy     => lc(substr($wday[$wday],0,3)),
			  Day    => sprintf("%-9s",$wday[$wday]),
			  Dy     => substr($wday[$wday],0,3),
			  RM     => uc($roman[$mon]),
			  rm     => $roman[$mon],
			  Q      => int(((($mon+1)/12)*4)+0.8),
			  CC     => substr($yr+2000,0,2),
			  WW     => sprintf("%02d", int(($yday+1)/7+.9)),
			  IW     => sprintf("%02d", int(($yday+$iwn_offset[$ystart_dow])/7+.9)),
			 );
	}
	return %h;
}

sub _pg_current {
	my ($mode,$with_tz,$now) = @_;
	my %formats = ( date      => "%04d-%02d-%02d", 
					timestamp => "%04d-%02d-%02d %02d:%02d:%02d.%06d", 
					time      => "%02d:%02d:%02d.%06d" );
	die "Unknown format '$mode'" unless $formats{$mode};
	$now ||= Time();
	my ($sec,$min,$hr,$day,$mon,$yr) = localtime($now);
	my $fraction = $now;
	$fraction =~ s/^\d+\.//;
	$fraction .= '0' while length($fraction)<6;
	my $cur;
	if ($mode eq 'timestamp') {
		$cur = sprintf("%04d-%02d-%02d %02d:%02d:%02d.%06d", $yr+1900,$mon+1,$day, $hr,$min,$sec,$fraction);
		$cur .= '+00' if $with_tz;
	} elsif ($mode eq 'date') {
		$cur = sprintf("%04d-%02d-%02d", $yr+1900,$mon+1,$day);
	} elsif ($mode eq 'time') {
		$cur = sprintf("%02d:%02d:%02d.%06d", $hr,$min,$sec,$fraction);
		$cur .= '+00' if $with_tz;
	}
	return $cur;
}


my %_interv_units = ( 'd'       => 24*60*60,
					  'day'     => 24*60*60,
					  'days'    => 24*60*60,
					  'min'     => 60,
					  'mins'    => 60,
					  'minutes' => 60,
					  'm'       => 60,
					  's'       => 1,
					  'seconds' => 1,
					  'sec'     => 1,
					  'secs'    => 1,
					  'hours'   => 60*60,
					  'hour'    => 60*60,
					  'h'       => 60*60,
					  'week'    => 7*24*60*60,
					  'weeks'   => 7*24*60*60,
					  'w'       => 7*24*60*60,
					  'mon'     => 30*24*60*60,
					  'month'   => 30*24*60*60,
					  'months'  => 30*24*60*60,
					  'y'       => 365*24*60*60,
					  'yr'      => 365*24*60*60,
					  'year'    => 365*24*60*60,
					  'years'   => 365*24*60*60,
);
sub _interval_to_seconds {
	my $str = lc(shift);
	my $sec = 0;
	my ($hr,$min) = ($1,$2) if $str=~ s/(\d\d):(\d\d)//;
	$sec += $hr * 60 * 60 if $hr;
	$sec += $min * 60 if $min;
	$sec += $1 if $str =~ s/:(\d\d)//;
	for my $u (keys %_interv_units) {
		if ($str =~ s{([\d\.]+)\s*$u}{}) {
			$sec += $1 * $_interv_units{$u};
		}
	}
	return $sec;
}

# Strangely, Perl tries to interpolate @_ if you say '$x = sub { atan2(@_) }', etc.
sub _atan2 { my ($x,$y) = @_; return atan2($x,$y); }
sub _cos { my $x = shift; return cos($x); }
sub _sin { my $x = shift; return sin($x); }

my @functions =
  (

   # Additions because of regex operator filtering: matches() and friends
   {
	name   => 'imatches_safe',
	argnum => 2,
	func   => sub {
		my ($col,$exp) = @_;
		$exp =~ s/[\?\+\*]//g; # remove quantifiers
		my $re;
		eval { $re = qr/$exp/i; };
		if ($@) {
			eval { $re = qr/\Q$exp\E/i; };
		}
		return 1 if $col =~ $re;
	}
   },

   {
	name   => 'matches_safe',
	argnum => 2,
	func   => sub {
		my ($col,$exp) = @_;
		$exp =~ s/[\?\+\*]//g; # remove quantifiers
		my $re;
		eval { $re = qr/$exp/; };
		if ($@) {
			eval { $re = qr/\Q$exp\E/; };
		}
		return 1 if $col =~ $re;
	}
   },

   {
	name   => 'matches',
	argnum => 2,
	func   => sub {
		my ($col,$exp) = @_;
		my $re;
		eval { $re = qr/$exp/; };
		return 1 if $col =~ $re;
	}
   },

   {
	name   => 'imatches',
	argnum => 2,
	func   => sub {
		my ($col,$exp) = @_;
		my $re;
		eval { $re = qr/$exp/i; };
		return 1 if $col =~ $re;
	}
   },
   
   # Interval calculation functions
   {
	name   => 'add_interval',
	argnum => 2,
	func   => sub { my $f = length($_[0])<=10 ? 'date' : 'timestamp'; _pg_current($f,0, _pgtime_to_time($_[0])+_interval_to_seconds($_[1])); }
   },
   {
	name   => 'subtract_interval',
	argnum => 2,
	func   => sub { my $f = length($_[0])<=10 ? 'date' : 'timestamp'; _pg_current($f,0, _pgtime_to_time($_[0])-_interval_to_seconds($_[1])); }
   },

   # Misc. utility functions, not based on Pg
   {
	name   => 'lower_latin1',
	argnum => 1,
	func   => sub {
		my $str = shift;
		$str =~ tr/A-ZÀ-Þ/a-zà-þ/;
		return $str;
	}
   },

   {
	name   => 'localeorder',
	argnum => 1,
	func   => $localeorder_func
   },

   {
	name   => 'locale',
	argnum => 0,
	func   => sub { return $locale },
   },


   # Mathemathical functions.
   # http://www.postgresql.org/docs/current/static/functions-math.html
   {
	name   => 'abs',
	argnum => 1,
	func   => sub { abs(shift) }
   },

   {
	name   => 'cbrt',
	argnum => 1,
	func   => sub { (shift)**(1/3) }
   },

   {
	name   => 'ceil',
	argnum => 1,
	func   => sub { POSIX::ceil(shift) }
   },

   {
	name   => 'degrees',
	argnum => 1,
	func   => sub { Math::Trig::rad2deg(@_) }
   },

   {
	name   => 'exp',
	argnum => 1,
	func   => sub { exp(shift) }
   },

   {
	name   => 'floor',
	argnum => 1,
	func   => sub { POSIX::floor(shift) }
   },

   {
	name   => 'ln',
	argnum => 1,
	func   => sub { log(shift) }
   },

   {
	name   => 'log',
	argnum => 1,
	func   => sub { POSIX::log10(shift) }
   },

   {
	name   => 'log',
	argnum => 2,
	func   => sub { my ($base,$x)=@_; return log($x)/log($base); }
   },

   {
	name   => 'mod',
	argnum => 2,
	func   => sub { (shift)%(shift) }
   },

   {
	name   => 'pi',
	argnum => 0,
	func   => sub { Math::Trig::pi }
   },

   {
	name   => 'exp',
	argnum => 1,
	func   => sub { exp(shift) }
   },

   {
	name   => 'pow',
	argnum => 2,
	func   => sub { (shift)**(shift) }
   },

   {
	name   => 'radians',
	argnum => 1,
	func   => sub { Math::Trig::deg2rad(@_) }
   },

   {
	name   => 'random', # NB! Overrides the builtin
	argnum => 0,
	func   => sub { rand() }
   },

   {
	name   => 'setseed',
	argnum => 1,
	func   => sub { my $seed=shift; $seed*=2**31 if $seed<1 && $seed>-1; srand($seed); return int($seed); }
   },

   {
	name   => 'sign',
	argnum => 1,
	func   => sub { $_[0] < 0 ? -1 : $_[0] == 0 ? 0 : +1; }
   },

   {
	name   => 'sqrt',
	argnum => 1,
	func   => sub { sqrt(shift) }
   },

   {
	name   => 'trunc',
	argnum => 1,
	func   => sub { int(shift) }
   },

   {
	name   => 'trunc',
	argnum => 2,
	func   => sub { my ($n,$l)=@_; return int($n) if $l<=0; my $f="%.".($l+1)."f"; $n=sprintf($f,$n); $n=~s/\d$//; return $n; }
   },

   {
	name   => 'acos',
	argnum => 1,
	func   => sub { Math::Trig::acos(@_) }
   },

   {
	name   => 'asin',
	argnum => 1,
	func   => sub { Math::Trig::asin(@_) }
   },

   {
	name   => 'atan',
	argnum => 1,
	func   => sub { Math::Trig::atan(@_) }
   },

   {
	name   => 'atan2',
	argnum => 2,
	func   => \&_atan2,
   },

   {
	name   => 'cos',
	argnum => 1,
	func   => \&_cos,
   },

   {
	name   => 'cot',
	argnum => 1,
	func   => sub { Math::Trig::cot(@_) }
   },

   {
	name   => 'sin',
	argnum => 1,
	func   => \&_sin,
   },

   {
	name   => 'tan',
	argnum => 1,
	func   => sub { Math::Trig::tan(@_) }
   },

   # String Functions
   # http://www.postgresql.org/docs/current/static/functions-string.html
   {
	name   => 'ascii',
	argnum => 1,
	func   => sub { ord(substr(shift,0,1)) }
   },
   
   {
	name   => 'bit_length',
	argnum => 1,
	func   => sub { length(shift)*8 }
   },
   
   {
	name   => 'btrim',
	argnum => 2,
	func   => sub { _trim('both',@_) }
   },
   
   {
	name   => 'char_length',
	argnum => 1,
	func   => sub { length(shift) }
   },
   
   {
	name   => 'character_length',
	argnum => 1,
	func   => sub { length(shift) }
   },
   
   {
	name   => 'chr',
	argnum => 1,
	func   => sub { chr(shift) }
   },
   
   {
	name   => 'convert',
	argnum => 2,
	func   => sub { _convert(shift,_latin1_symbol(),uc(shift)) }
   },

   {
	name   => 'convert',
	argnum => 3,
	func   => sub { _convert(shift,uc(shift),uc(shift)) }
   },
   
   {
	name   => 'decode',
	argnum => 2,
	func   => sub { my($txt,$typ)=@_; return $_decode{lc($typ)}->($txt); }
   },
   
   {
	name   => 'encode',
	argnum => 2,
	func   => sub { my($txt,$typ)=@_; return $_encode{lc($typ)}->($txt); }
   },
   
   {
	name   => 'initcap',
	argnum => 1,
	func   => sub {
		my $str=ucfirst(shift); 
		$str=~s[(\s\w)]{uc $1}gie; #}ge;
		return $str;
	}
   },
   
   {
	name   => 'length',
	argnum => 1,
	func   => sub { return length(shift) }
   },
   
   {
	name   => 'lpad',
	argnum => 2,
	func   => sub { _pad('left',@_,' ') }
   },

   {
	name   => 'lpad',
	argnum => 3,
	func   => sub { _pad('left',@_) }
   },
   
   {
	name   => 'ltrim',
	argnum => 2,
	func   => sub { _trim('left',@_) }
   },
   
   {
	name   => 'md5', # new in Pg 7.4
	argnum => 1,
	func   => sub { Digest::MD5::md5_hex(shift); } #))
   },
   
   {
	name   => 'octet_length',
	argnum => 1,
	func   => sub { length(shift) }
   },
   
   {
	name   => 'position',
	argnum => 2,
	func   => sub { my($part,$whole)=@_; return index($whole,$part)+1; }
   },
   
   {
	name   => 'pg_client_encoding',
	argnum => 0,
	func   => sub { return 'SQL_ASCII' }
   },
   
   {
	name   => 'quote_ident',
	argnum => 1,
	func   => sub { local($_)=shift; s/\"/\\\"/g; return qq!"$_"!; } #"
   },
   
   {
	name   => 'quote_literal',
	argnum => 1,
	func   => sub { local($_)=shift; s/\'/\'\'/g; s/\\/\\\\/g; return qq!'$_'!; }
   },
   
   {
	name   => 'repeat',
	argnum => 2,
	func   => sub { $_[0] x $_[1] }
   },
   
   {
	name   => 'replace',
	argnum => 3,
	func   => sub { $_[0] =~ s!\Q$_[1]\E!$_[2]!g; $_[0]; }
   },

   {
	name   => 'rpad',
	argnum => 2,
	func   => sub { _pad('right',@_,' ') }
   },

   {
	name   => 'rpad',
	argnum => 3,
	func   => sub { _pad('right',@_) } 
   },
   
   {
	name   => 'rtrim',
	argnum => 2,
	func   => sub { _trim('right',@_) }
   },
   
   {
	name   => 'split_part',
	argnum => 3,
	func   => sub { my ($str,$delim,$i) = @_; $i||=1; return (split(/\Q$delim\E/,$str))[$i-1]; }
   },
   
   {
	name   => 'strpos',
	argnum => 2,
	func   => sub { index(shift,shift)+1 }
   },
   
   {
	name   => 'substring',
	argnum => 2,
	func   => sub { my ($str,$pat)=@_; return $1 if $str=~m{($pat)}; }
   },
   # NB: substring(string from pattern for escape) is NOT SUPPORTED
   {
	name   => 'substring',
	argnum => 3,
	func   => sub { substr($_[0],$_[1]-1,$_[2]); }
   },
   
   {
	name   => 'to_ascii', # assumes latin1 input
	argnum => 1,
	func   => sub { _to_ascii(@_) }
   },

   {
	name   => 'to_ascii',
	argnum => 2,
	func   => sub { _to_ascii(@_) }
   },
   
   {
	name   => 'to_hex',
	argnum => 1,
	func   => sub { sprintf("%x",shift) }
   },
   
   {
	name   => 'translate',
	argnum => 3,
	func   => sub { my ($str,$from,$to) = @_; s/\//\\\//g for ($from,$to); eval '$str =~ '."tr/$from/$to/"; return $str; }
   },
   
   {
	name   => 'trim',
	argnum => 1,
	func   => sub { _trim('both',shift) }
   },

   {
	name   => 'trim',
	argnum => 2,
	func   => sub { _trim('both',@_) },
   },
   
   {
	name   => 'trim',
	argnum => 3,
	func   => sub { _trim('both',@_) }
   },

   # Data Type Formatting
   # http://www.postgresql.org/docs/current/static/functions-formatting.html
   {
	name   => 'to_char', # Limited support because of datatype issues
	argnum => 2,
	func   => sub { _to_char(_pgtime_to_time(shift),shift) }
   },
   
   {
	name   => 'to_date',
	argnum => 2,
	func   => sub { die "TODO: to_date" }
   },

   {
	name   => 'to_timestamp',
	argnum => 2,
	func   => sub { die "TODO: to_timestamp" }
   },

   {
	name   => 'to_number',
	argnum => 2,
	func   => sub { die "TODO: to_number" }
   },

   # Date/Time Functions
   # http://www.postgresql.org/docs/current/static/functions-datetime.html
   # NB! need to handle datetime-calculations and datetime/date casting operators
   # NB! need filter for (t1,t2) OVERLAPS (t3,t4)
   {
	name   => 'age',
	argnum => 1,
	func   => sub { die "TODO: age" }
   },
   
   {
	name   => 'age',
	argnum => 2,
	func   => sub { die "TODO: age 2" }
   },

   {
	name   => 'current_date',
	argnum => 0,
	func   => sub { _pg_current('date',0) }
   },

   {
	name   => 'current_time',
	argnum => 0,
	func   => sub { _pg_current('time',0) }
   },

   {
	name   => 'current_timestamp',
	argnum => 0,
	func   => sub { _pg_current('timestamp',0) }
   },

   {
	name   => 'date_part', # NB! works only for timestamp, not interval
	argnum => 2,
	func   => sub { _extract($_[0],_pgtime_to_time($_[1])) }
   },
   
   {
	name   => 'date_trunc', # NB! works only for timestamp, not interval
	argnum => 2,
	func   => sub { _date_trunc(@_) }
   },
   
   {
	name   => 'extract', # NB! works only for timestamp, not interval
	argnum => 2,
	func   => sub { _extract($_[0],_pgtime_to_time($_[1])) }
   },

   {
	name   => 'isfinite', # timestamp/interval
	argnum => 1,
	func   => sub { die "TODO: isfinite" }
   },
   
   {
	name   => 'localtime',
	argnum => 0,
	func   => sub {  _pg_current('time',0) }
   },
   
   {
	name   => 'localtimestamp',
	argnum => 0,
	func   => sub {  _pg_current('timestamp',0) }
   },

   {
	name   => 'now',
	argnum => 0,
	func   => sub { _pg_current('timestamp',0) }
   },
   
   {
	name   => 'timeofday',
	argnum => 0,
	func   => sub { scalar localtime; }
   },

   # Sequence Manipulation Functions
   # http://www.postgresql.org/docs/current/static/functions-sequence.html
   {
	name   => 'nextval',
	argnum => 1,
	func   => sub { _nextval(@_) }
   },
   {
	name   => 'currval',
	argnum => 1,
	func   => sub { _currval(@_)  }
   },
   {
	name   => 'lastval',
	argnum => 0,
	func   => sub { _lastval()  }
   },
   {
	name   => 'setval',
	argnum => 2,
	func   => sub { _setval(@_) }
   },
   {
	name   => 'setval',
	argnum => 3,
	func   => sub { _setval(@_) }
   },

   # Misc Functions
   # http://www.postgresql.org/docs/current/static/functions-misc.html
   # Most of these are omitted.
   {
	name   => 'current_user',
	argnum => 0,
	func   => sub { (getpwuid $>)[0] }
   },
   {
	name   => 'session_user',
	argnum => 0,
	func   => sub { (getpwuid $>)[0] }
   },
   {
	name   => 'user',
	argnum => 0,
	func   => sub { (getpwuid $>)[0] }
   },
   
  );

# Transforms a stored procedure into a coderef
sub _sp_func {
	my $dbh = shift;
	my $name = shift;
	my $sql = shift;
	my $ret = sub {
		my @args = @_;
		die "No more than at most 9 arguments supported" if @args > 9;
		die "Non-SELECT statements not supported" unless $sql =~ /^\s*select\b/i;
		for (@args) {
			unless (defined $_) {
				$_ = 'NULL';
				next;
			}
			next if /^[\-\+]?\d+(?:\.\d+)$/;
			s/\'/\'\'/g;
			$_ = "'".$_."'";
		}
		if (@args && $sql =~ /\$\d/) {
			for my $i (1..9) { # supports only up to 9 args
				$sql =~ s/\$${i}/$args[$i-1]/g;
			}
		}
		my $res = $dbh->selectall_arrayref($sql);
		return undef unless $res && @$res;
		die "User-defined SQL function '$name' returns more than 1 row for values [ @_ ]" if @$res > 1;
		my $row = $res->[0];
		die "User-defined SQL function '$name' returns more than 1 column for values [ @_ ]" if @$row > 1;
		return $row->[0];
	};
	return $ret;
}

sub _register_builtin_functions {
	my $dbh = shift; # real sqlite handle
	for (@functions) {
		$dbh->func( $_->{name}, $_->{argnum}, $_->{func}, "create_function" );
	}
	$dbh->func( "avg", 1, 'DBD::PgLite::Aggregate::avg', "create_aggregate" );
}

sub _register_stored_functions {
	my $pglite_dbh = shift;
	my $real_dbh = $pglite_dbh->{D};
	my $check = $real_dbh->selectrow_array("select name from sqlite_master where type = 'table' and name = 'pglite_functions'");
	if ($check) {
		my $sproc = $real_dbh->selectall_arrayref("select name, argnum, type, sql from pglite_functions",{Columns=>{}});
		for my $sp (@$sproc) {
			if ($sp->{type} eq 'perl') {
				my $func = eval $sp->{sql};
				if ($@) {
					warn "WARNING: invalid stored perl function '$sp->{name}' - skipping ($@)\n";
				} else {
					$real_dbh->func( $sp->{name}, $sp->{argnum}, $func, "create_function" );
				}
			} else {
				$real_dbh->func( $sp->{name}, $sp->{argnum}, 
								 _sp_func($pglite_dbh,$sp->{name},$sp->{sql}),
								 "create_function" );
			}
		}
	}
}

### driver methods ######

package DBD::PgLite::dr;
our $imp_data_size = 0;    # strongly suggested by DBI
sub connect {
	my ($drh, $dsn, $user, $auth, $attr) = @_;
	my %attr = (RaiseError=>1,PrintError=>0,AutoCommit=>1,FilterSQL=>1);
	if (ref $attr) {
		$attr{$_} = $attr->{$_} for keys %$attr;
	}
	my $use_filter = $attr{FilterSQL};
	delete $attr{FilterSQL};
	my $real_dbh = DBI->connect("dbi:SQLite:$dsn",$user,$auth,\%attr)
	  or die "Could not connect with dbi::SQLite:$dsn\n";
    DBD::PgLite::_register_builtin_functions($real_dbh);
	my $handle = DBI::_new_dbh ($drh, {
		'Name'      => $attr{mbl_dsn},
		'User'      => $user,
		'D'         => $real_dbh,
		'Seq'       => undef, # for sequence support
		'FilterSQL' => $use_filter,
		%$attr,
	});
	DBD::PgLite::_register_stored_functions($handle);
	DBD::PgLite::setDbh($handle);
	return $handle;
}
sub disconnect_all { my $dbh = shift; $dbh->{D}->disconnect_all(@_) if $dbh && $dbh->{D}; } # required by DBI
sub DESTROY { my $x=shift; $x->{D}->DESTROY(@_) if $x && $x->{D}; }  # required by DBI ()

### database handle methods ######

package DBD::PgLite::db;
our $imp_data_size = 0;    # strongly suggested by DBI

sub STORE { my ($h,$k,$v) = @_; return $h->{D}->STORE($k,$v); }
sub FETCH { my ($h,$k) = @_; return $h->{D} if $k eq 'D'; return $h->{D}->FETCH($k); }

sub do               {
	my ($dbh,$sql,$attr,@bind) = @_;
	$attr ||= {};
	my $sth = $dbh->prepare($sql,$attr);
	return $sth->execute(@bind);
}
sub table_info       { shift->{D}->table_info(@_); }
sub column_info      { shift->{D}->column_info(@_); }
sub rows             { shift->{D}->rows(@_); }
sub quote            { shift->{D}->quote(@_); }
sub primary_key_info { shift->{D}->primary_key_info(@_); }
sub primary_key      { shift->{D}->primary_key(@_); }
sub foreign_key_info { shift->{D}->foreign_key_info(@_); }
sub get_info         { shift->{D}->get_info(@_); }
sub ping             { shift->{D}->ping(@_); }
sub begin_work       { DBD::PgLite::setTransaction(1); DBD::PgLite::setTime(); shift->{D}->begin_work(@_); }
sub commit           { DBD::PgLite::setTransaction(0); DBD::PgLite::setTime(); shift->{D}->commit(@_); }
sub rollback         { DBD::PgLite::setTransaction(0); DBD::PgLite::setTime(); shift->{D}->rollback(@_); }


sub prepare {
	my ($dbh,$statement,$attr) = @_;
	my $filtered = DBD::PgLite::Filter::filter_sql($dbh,$statement,$attr);
	return $dbh->{D}->prepare($filtered,$attr);
}
sub selectrow_array {
	my ($dbh,$statement,$attr,@bind) = @_; 
	my $filtered = DBD::PgLite::Filter::filter_sql($dbh,$statement,$attr);
	return $dbh->{D}->selectrow_array($filtered,$attr,@bind);
}
sub selectrow_arrayref { 
	my ($dbh,$statement,$attr,@bind) = @_; 
	my $filtered = DBD::PgLite::Filter::filter_sql($dbh,$statement,$attr);
	return $dbh->{D}->selectrow_arrayref($filtered,$attr,@bind);
}
sub selectrow_hashref { 
	my ($dbh,$statement,$attr,@bind) = @_; 
	my $filtered = DBD::PgLite::Filter::filter_sql($dbh,$statement,$attr);
	return $dbh->{D}->selectrow_hashref($filtered,$attr,@bind);
}
sub selectall_arrayref { 
	my ($dbh,$statement,$attr,@bind) = @_; 
	my $filtered = DBD::PgLite::Filter::filter_sql($dbh,$statement,$attr);
	return $dbh->{D}->selectall_arrayref($filtered,$attr,@bind);
}
sub selectall_hashref { 
	my ($dbh,$statement,$kf,$attr,@bind) = @_; 
	my $filtered = DBD::PgLite::Filter::filter_sql($dbh,$statement,$attr);
	return $dbh->{D}->selectall_hashref($filtered,$kf,$attr,@bind);
}
sub selectcol_arrayref { 
	my ($dbh,$statement,$attr,@bind) = @_; 
	my $filtered = DBD::PgLite::Filter::filter_sql($dbh,$statement,$attr);
	return $dbh->{D}->selectcol_arrayref($filtered,$attr,@bind); #}
}

### statement handle methods ######

package DBD::PgLite::st;
our $imp_data_size = 0;    # strongly suggested by DBI

# We should not need any methods in this package, as any statement
# handles will already be blessed into DBD::SQLite::st.

### dbh method additions/overrides ######

package DBD::PgLite::Filter;

# Regexes used in filter_sql()
my $end_re = qr/(?=[\s\,\)\:\|])|$/;
my $col_re = qr/\b[\w+\.]+$end_re/; # column name, keyword or number
my $qs_re  = qr/(?:''|'(?:[^\']|'')+')$end_re/; # quoted string
my $func_simple_re = qr/\b\w+\s*\(\s*(?:$col_re|$qs_re)?(?:\s*,\s*(?:$col_re|$qs_re))*\s*\)/; # simple function call
my $func_complex_re = qr/\b\w+\s*\(\s*(?:$col_re|$qs_re|$func_simple_re)(?:\s*,\s*(?:$col_re|$qs_re|$func_simple_re))*\s*\)/; #complex function call
my $chunk_re = qr/(?:$col_re|$qs_re|$func_simple_re|$func_complex_re)/;
my $join_re = qr/\s+NATURAL\s+(?:LEFT\s+|RIGHT\s+|FULL\s+)?(?:OUTER\s+|INNER\s+|CROSS\s+)?JOIN\s+/i;

#######################)!}}]];;;;!!!///'''''''''''""""""""""

sub filter_sql {
	my ($dbh,$sql,$attr) = @_;
	# warn "[ UNFILTERED SQL:\n$sql\n]\n" if $ENV{PGLITEDEBUG}>1;
	# Prefilter SQL
	$sql = ($dbh->{prefilter}->($sql) || $sql)  if ref $dbh->{prefilter}  eq 'CODE';
	$sql = ($attr->{prefilter}->($sql) || $sql) if ref $attr->{prefilter} eq 'CODE';
	# Fix time for transaction
	DBD::PgLite::setTime() unless DBD::PgLite::getTransaction();
	# Strip out all trailing ";" and make sure statement ends in space (don't ask!)
	while ($sql =~ s/\s*\;\s*$//s) { next; }
	$sql .= " ";
	# NB! may not be healthy for non-SELECTs...
	# First determine whether filtering has been turned off
	$attr ||= {};
	if (exists $attr->{FilterSQL}) {
		return $sql unless $attr->{FilterSQL};
	}
	if ($dbh->{D}) {
		return $sql unless $dbh->{FilterSQL} || $attr->{FilterSQL};
		$dbh = $dbh->{D};
	}
	my %interval_func = (
						  '+' => 'add_interval', 
						  '-' => 'subtract_interval'
						);
	# Protect quoted strings from the unsafe transformations below
	$sql =~ s{($qs_re)}{$1 eq "''" ? "''" : "'".unpack("H*",$1)."'"}gie;
	for ($sql) {
		# Booleans ('t' = 74 hex, 'f' = 66 hex, "'" = 27 hex)
		# (a) In conjunction with operators
		$sql =~ s{($chunk_re)\s*=\s*(?:false|False|FALSE|\'276627\')}{NOT $1}g;
		$sql =~ s{($chunk_re)\s*(?:\!=|<>)\s*(?:false|False|FALSE|\'276627\')}{$1}g;
		$sql =~ s{($chunk_re)\s*=\s*(?:true|True|TRUE|\'277427\')}{$1}g;
		$sql =~ s{($chunk_re)\s*(?:\!=|<>)\s*(?:true|True|TRUE|\'277427\')}{NOT $1}g;
		# (b) freestanding
		$sql =~ s{\'277427\'::bool(?:ean)?}{1}gi;
		$sql =~ s{\'276627\'::bool(?:ean)?}{0}gi;
		$sql =~ s{\bTRUE\b}{1}gi;
		$sql =~ s{\bFALSE\b}{0}gi;
		# Time zone not supported
		s{\swith(?:out)?\s+time\s+zone}{}gi;
		# Casting to date supported as an alias for to_char...
		s{($chunk_re)::date\b}{to_char($1,'YYYY-MM-DD')}gi;
		# Casting to integer supported as an alias for round
		s{($chunk_re)::int(?:eger)?\b}{round($1)}gi;
		# ... but casting in general not supported
		s{\:\:\w+(?:\([\d\,]+\))?}{}gi;
		# Non-paren functions -- add parentheses
		for (qw[CURRENT_DATE CURRENT_TIMESTAMP CURRENT_TIME LOCALTIMESTAMP LOCALTIME
                CURRENT_USER SESSION_USER USER]) {
			$sql =~ s/([\s\,\(])($_)([\s\,])/$1$2()$3/gi;
		}
		# ILIKE => LIKE
		s{\bI(LIKE)\b}{$1}gi;
		# extract(field from dtvalue)
		s{\b(EXTRACT\s*\(\s*)\'?(\w+)\'?\s+FROM\s+}{$1'$2',}gi;
		# trim(both 'x' from 'xAx'): reverse arguments
		s{\bTRIM\s*\(\s*BOTH\s+($chunk_re)\s+FROM\s+($chunk_re)\s*\)}{BTRIM($2,$1)}gi;
		s{\bTRIM\s*\(\s*LEADING\s+($chunk_re)\s+FROM\s+($chunk_re)\s*\)}{LTRIM($2,$1)}gi;
		s{\bTRIM\s*\(\s*TRAILING\s+($chunk_re)\s+FROM\s+($chunk_re)\s*\)}{RTRIM($2,$1)}gi;
		# substring(string FROM int FOR int)
		s{\b(SUBSTRING\s*\()\s*($chunk_re)\s+FROM\s+($chunk_re)\s+FOR\s+}{$1$2,$3,}gi;
		# substring(string FROM pattern)
		s{\b(SUBSTRING\s*\()\s*($chunk_re)\s+FROM\s+}{$1$2,}gi;
		# position('x' IN 'y')
		s{(POSITION\s*\()\s*($chunk_re)\s+IN\s+}{$1$2,}gi;
		# convert(x USING conversion_name)
		s{(CONVERT\s*\()\s*($chunk_re)\s+USING\s+}{$1$2,}gi;
		# Regex operator filters
		s{($chunk_re\s+)~(\s+$chunk_re)}{MATCHES($1,$2)}g;
		s{($chunk_re\s+)~\*(\s+$chunk_re)}{IMATCHES($1,$2)}g;
		s{($chunk_re\s+)\!~(\s+$chunk_re)}{NOT MATCHES($1,$2)}g; #]]]}}''
		s{($chunk_re\s+)\!~\*(\s+$chunk_re)}{NOT IMATCHES($1,$2)}g; #]]]}}''
		# Interval/datetime calculation - VERY limited support
		s{($chunk_re\s+)(\+|\-)\s*INTERVAL(\s+$chunk_re)}{$interval_func{$2}($1,$3)}i;
	}
	# Solve table aliases problem.
	# ("select x.a, y.b from table t1 as x t2 as y" does not work)
	my $from_clause = $1 if $sql =~ /\s+FROM\s+(.*?)(?:\sWHERE|\sON|\sUSING|\sGROUP\s+BY|\sHAVING|\sORDER\s+BY|\sLIMIT|\;|$)/si;
	if ($from_clause) {
		my @ftables = split /\s*(?:,|(?:NATURAL\s+|LEFT\s+|RIGHT\s+|FULL\s+|OUTER\s+|INNER\s+|CROSS\s+)*JOIN)\s*/i, $from_clause;
		foreach my $tb (@ftables) {
			$tb =~ s/[\(\)]/ /g;
			$tb =~ s/^\s+//;
			$tb =~ s/\s+$//;
			if ($tb =~ /\s/) {
				my ($real,$alias) = split /\s+(?:AS\s+)?/i, $tb;
				next unless $real && $alias;
				$sql =~ s/\Q$tb\E/$real/g;
				$sql =~ s/\b$alias\.(\w+)/$real.$1/g;
				$sql =~ s/\b$alias\.\*([,\s])/$real.*$1/g;
			}
		}
	}
	# Solve ambiguous column problem in natural join
	# ("select cat_id, sc_id, cat_name, sc_name from cat natural join subcat" does not work)
	if ($sql =~ $join_re) {
		my @tables = ($sql =~ /(\w+)$join_re/gi);
		push @tables, ($sql =~ /$join_re(\w+)/gi);
		my (%seen,%col);
		for my $tab (@tables) {
			next if $seen{$tab}++;
			my $res = $dbh->selectall_arrayref("pragma table_info($tab)",{Columns=>{}});
			next unless $res && ref $res eq 'ARRAY';
			for my $row (@$res) {
				if ($col{ $row->{name} }) {
					$col{ $row->{name} }->[0]++;
				}
				else {
					$col{ $row->{name} } = [1, $tab];
				}
			}
		}
		for my $c (keys %col) {
			next unless $col{$c}->[0] > 1;
			if ($from_clause && $from_clause =~ /\([^\)]*\b$col{$c}->[1]\b[^\)]*\)/) {
				# Table grouping in joins addles SQLite's brains.
				# It messes aliases up (and indeed table referencing in colnames generally).
				$sql =~ s/\b$col{$c}->[1]\.(\w+)/$1/g;
			}
			else {
				$sql =~ s/([^\w\.])$c([^\w\.])/$1$col{$c}->[1].$c$2/g;
			}
		}
	}
	# Unprotect quoted strings
	$sql =~ s{\'([a-fA-F0-9]+)\'}{pack("H*",$1)}gie; #};\';
	# Catch implicit NEXTVAL calls
	$sql = catch_nextval($sql,$dbh);
	# Postfilter SQL
	$sql = ($dbh->{postfilter}->($sql) || $sql)  if ref $dbh->{postfilter}  eq 'CODE';
	$sql = ($attr->{postfilter}->($sql) || $sql) if ref $attr->{postfilter} eq 'CODE';
	# warn "[ FILTERED SQL:\n$sql\n]\n" if $ENV{PGLITEDEBUG};
	return $sql;
}

sub catch_nextval {
	my ($sql,$dbh) = @_;
	return $sql unless $sql =~ /^\s*INSERT\s+INTO\s+([\w\.]+)\s+\(([^\)]+)\)\s+VALUES\s+\(/si;
	my $table = lc($1);
	my $colstr = lc($2);
	my @pk = $dbh->primary_key(undef,undef,$table);
	return $sql unless @pk==1;
	$colstr =~ s/^\s+//;
	$colstr =~ s/\s+$//;
	my %cols = map { (lc($_)=>1) } split /\s*,\s*/, $colstr;
	return $sql if $cols{lc($pk[0])};
	my $seqname = $table . '_' . lc($pk[0]) . '_seq';
	my $val = 0;
	eval { $val = $dbh->selectrow_array("SELECT NEXTVAL('$seqname')") };
	if ($val) {
		$sql =~ s/(INTO\s+[\w\.]+\s+\()/$1$pk[0], /i;
		$sql =~ s/(VALUES\s+\()/$1$val, /i;
	}
	return $sql;
}


### Aggregate function: avg ####

package DBD::PgLite::Aggregate::avg;

sub new { bless {sum=>0,count=>0}, shift; }
sub step {
	my ($self,$val) = @_; 
	return unless defined $val; # don't count nulls as zero
	$self->{count}++;
	$self->{sum}+=$val;
}
sub finalize {
	my $self = shift;
	return undef unless $self->{count};
	return $self->{sum}/$self->{count};
}

1;
__END__


=pod

=head1 NAME

DBD::PgLite - PostgreSQL emulation mode for SQLite

=head1 SUMMARY

  use DBI;
  my $dbh = DBI->connect('dbi:PgLite:dbname=file');
  # The following PostgreSQL-flavoured SQL is invalid 
  # in SQLite directly, but works using PgLite
  my $sql = q[
    SELECT
      news_id, title, cat_id, cat_name, sc_id sc_name,
      to_char(news_created,'FMDD.FMMM.YYYY') AS ndate
    FROM
      news
      NATURAL JOIN x_news_cat
      NATURAL JOIN cat
      NATURAL JOIN subcat
    WHERE
      news_active = TRUE
      AND news_created > NOW() - INTERVAL '7 days'
  ];
  my $res = $dbh->selectall_arrayref($sql,{Columns=>{}});
  # From v. 0.05 with full sequence function support
  my $get_nid = "SELECT NEXTVAL('news_news_id_seq')";
  my $news_id = $dbh->selectrow_array($get_nid);

=head1 DESCRIPTION

The module automatically and transparently transforms a broad range of
SQL statements typical of PostgreSQL into a form suitable for use in
SQLite. This involves both (a) parsing and filtering of the SQL; and
(b) the addition of several PostgreSQL-compatible functions to SQLite.

Mainly because of datatype issues, support for many PostgreSQL
features simply cannot be provided without elaborate planning and
detailed metadata. Since this module is intended to be usable with any
SQLite3 database, it follows that the emulation is limited in several
respects. An overview of what works and what doesn't is given in the
following section on PostgreSQL Compatibility.

DBD::PgLite has support of a sort for stored procedures. This is
described in the Extras section below. So are the few database
functions defined by this module which are not in PostgreSQL. Finally,
the Extras section contains a brief mention of the
DBD::PgLite::MirrorPgToSQLite companion module.

If you do not want SQL filtering to be turned on by default for the
entire session, you can connect setting the connection attribute
I<FilterSQL> to a false value:

  my $dbh = DBI->connect("dbi:PgLite:dbname=$fn",
                         undef, undef, {FilterSQL=>0});

To turn filtering off (or on) for a single statement, you can specify
I<FilterSQL> option as a statement attribute, e.g.:

  $dbh->do($sql, {FilterSQL=>0}, @bind);
  my $sth = $dbh->prepare($sql, {FilterSQL=>0});
  $res = $dbh->selectall_arrayref($sql, {FilterSQL=>0}, @bind);

It is possible to specify user-defined pre- and postfiltering
routines, both globally (by specifying them as attributes of the
database handle) and locally (by specifying them as statement
attributes):

  $dbh = DBI->connect("dbi:PgLite:$file",undef,undef,
                      {prefilter=>\&prefilter});
  $res = $dbh->selectall_arrayref($sql,
                                  {postfilter=>\&postfilter},
                                  @bind_values);

The pre-/postfiltering subroutine receives the SQL as parameter and is
expected to return the changed SQL.

=head1 STATUS OF THE MODULE

This module was initially developed using SQLite 3.0 and PostgreSQL
7.3, but it should be fully compatible with newer versions of both
SQLite (3.1 and 3.2 have been tested) and PostgreSQL (8.1 has been
tested).

Support for SELECT statements and the WHERE-conditions of DELETE and
UPDATE statements is rather good, though still incomplete. The module
especially focuses on NATURAL JOIN differences and commonly used,
built-in PostgreSQL functions.

Support for inserted/updated values in INSERT and UPDATE statements
could use some improvement but is useable for simple things.

There is no support for differences in DDL.

The SQL transformations used are not based on a formal grammar but on
applying simple regular expressions. An obvious consequence of this is
that they may depend excessively on the author's SQL style. YMMV. (I
would however like you to contact me if you come across some SQL
statements which you feel should work but that don't).

The development of this module has been driven by personal needs, and
so is likely to be even more one-sided than the above description
suggests.

=head1 POSTGRESQL COMPATIBILITY

In this section, the PostgreSQL functions and operators supported by
the module are enumerated.

=head2 Regex operators

=over

=item *

The regex operators "~", "~*", "!~" and "!~*" are transformed into
calls to the user-defined function matches(). The regex flavour
supported is Perl, not plain vanilla POSIX, so some incompatibilities
may arise.

=item *

Note that for ease of parsing, whitespace before and after the
operator is required for the filtering to succeed. So "col ~ 'pat'"
works, but "col~'pat'" doesn't.

=item *

"SIMILAR TO" is not supported.

=item *

ILIKE is quietly changed to LIKE. LIKE in SQLite is case-insensitive
for 7-bit characters. In future, ILIKE will probably be handled more
elegantly, and LIKE will be redefined so as to be more like
PostgreSQL.

=back

=head2 Math Functions

=over 4

=item *

Added: abs, cbrt, ceil, degrees, exp, floor, ln, log (1- and
2-argument forms), mod, pi, pow, radians, sign, sqrt, trunc (1- and
2-argument forms), acos, asin, atan, atan2, cos, cot, sin, tan.

=item *

random() exists in SQLite but was redefined to conform better with
PostgreSQL in terms of value range. setseed() was also added, but is
not entirely compatible with PostgreSQL in the sense that setting the
random seed does not engender the same sequence of pseudo-random
numbers as it would in PostgreSQL.

=item *

SQLite already has a handful of mathematical functions which have been
left alone, notably round() (1- and 2-argument forms).

=back

=head2 String Functions

The only string functions which are present natively in SQLite are
substr(), lower() and upper(). These have been left alone. Added
functions are the following:

=over 4

=item

ascii, bit_length, btrim, char_length, character_length, chr, convert
(1- and 2-arg), decode, encode, initcap, length, lpad, ltrim, md5,
octet_length, position, pg_client_encoding (always 'SQL_ASCII'),
quote_ident, quote_literal, repeat, replace, rpad, rtrim, split_part,
strpos, substring(string,offset,length), substring(string from
pattern), to_ascii (assumes latin-1 input), to_hex, translate, trim.

=back

Except for convert(), where another input encoding can be specified
explicitly, these functions all assume that the strings are in an
8-bit character set, preferably iso-8859-1.

The little-used idiom "substring(string from pattern for escape)"
(where 'pattern' is not a POSIX regular expression but a SQL pattern)
is not supported. Otherwise support for string functions is pretty
complete.


=head2 Data Type Formatting Functions

The implementation of these functions is impeded by the sparse type
system employed by SQLite. Workarounds are possible, however, so this
area will probably be better covered in future.

=over

=item *

to_char(timestamp, format) is mostly supported. There is support for
most formatting strings (all except 'Y,YYY', 'IYYY', 'IYY', 'IY', 'I',
'J', 'TZ', and 'tz'). The FM prefix is supported for 'MM', 'DD' and
'HH*', but not otherwise. Other prefixes are not supported.

=item *

to_char(interval, format) and to_char(number, format) are not
currently supported. Nor are to_date(), to_timestamp() and
to_number() (yet).

=back


=head2 Date/Time Functions

Again, SQLite's intrinsically bad support for dates and intervals
makes this area somewhat hard to cover properly. Function support is
as follows; also note the caveats below:

=over

=item *

Supported: now, current_date, current_time, current_datetime,
date_part (with timestamps, not intervals), date_trunc, extract (with
timestamps, not intervals), localtime, localtimestamp, timeofday.

=item *

Not supported: age, isfinite, overlaps.

=back

Versions of SQLite 3.1 and later support some of these functions,
e.g. current_date. In these versions the built-in will be overridden.

The module makes no distinction between time/timestamp with and
without time zone. It is assumed that times and timestamps are either
all GMT or all localtime; time zone information is silently
discarded. This may change later.

Support for calculations with dates and intervals is still very
limited. Basically, what is supported are expressions of the form
"expr +/- interval 'descr'" where expr reduces to a timestamp or date
value.

If a transaction is started with begin_work(), the time as represented
by now() and friends is "frozen" in the same way as in PostgreSQL
until commit() or rollback() are called. A transaction started by
simply running the SQL statement "BEGIN" does not, however, trigger
this behaviour. Nor is the time automatically "unfrozen" when an error
occurs during a transaction; you need to catch exceptions and call
rollback() manually.

=head2 Sequence Manipulation Functions

=over

=item *

There is now full support for all explicit invocations of the sequence
functions nextval(), setval(), currval() and lastval(). Sequences are
emulated using the table pglite_seq. (This works even with multiple
connections to the same database file, some of which are using
transactions, since SQLite transactions lock the whole database file,
luckily eliminating any risk of two connections getting the same value
from a nextval() call).

Please be aware that sequences are autogenerated if they do not
exist. Be careful to specify the appropriate sequence names or you
will get unexpected results.

If a sequence being autogenerated ends with '_seq' and has a name
which seems to match an existing table + an integer column from that
table (tablename_colname_seq), it is given an initial value based on
the maximum value in the column in question.

There is as yet no support for CREATE SEQUENCE statements. Use the
autogeneration feature to create sequences.

Implicit calls to NEXTVAL() by omitting the serial column from the
column list in an INSERT are caught in most cases. The main conditions
that must be fulfilled for this to work are: (1) that the column in
question is an integer column which is the sole primary key on the
table; and (2) that the statement is a normal INSERT with a column
list and a VALUES clause (and not, e.g., a statement of the form
INSERT INTO x SELECT * FROM y).

There is as yet no interaction with the SQLite builtin
autoincrement/last_insert_rowid() functionality in connection with the
sequence function support.

=back

=head2 Aggregate Functions

=over

=item *

max(), min(), count() and sum() are already supported by SQLite and
have been left alone. Note that the construct "count(distinct
colname)" is not supported unless the SQLite version being used
supports it (3.2.6 and later).

=item *

avg() has been added.

=item *

stddev() and variance() are not supported.

=back

=head2 A Note on Casting

Casting using the construct "::datatype" is not supported in
general. However, "::int", "::date" and "::bool" should work as
expected.  All other casts are silently discarded.

=head2 A Note on Booleans

This module assumes that booleans will be stored as numeric values in
the SQLite database. SQLite interprets 0 as false and any non-zero
numeric value as true. Accordingly, expressions such as "= TRUE" and
"= 't'" are simply removed in SELECT and DELETE statements. Likewise,
"expr = FALSE" is turned into "NOT expr" before being passed on to
SQLite.

In INSERT and DELETE statements, TRUE and FALSE (as well as 't'::bool
and 'f'::bool - but not 't' and 'f' by themselves) are turned into 1
and 0.

=head2 Current_user etc.

The functions current_user(), session_user() and user() - with or
without parentheses - all mean the same thing. They return the
username of the effective uid.

=head2 Other Functions

The main groups of other functions (not supported by this module at
all) are:

=over

=item *

Database/user information functions: Aside from
current_user/session_user/user, which were mentioned above, no
functions in this group are supported. This includes
current_database(), current_schema(), all functions with names
starting with 'pg_' and 'has_', obj_description and col_description.
See http://www.postgresql.org/docs/current/static/functions-misc.html

=item *

Array functions are not implemented - see
http://www.postgresql.org/docs/current/static/functions-array.html

=item *

Binary string (BYTEA) functions are not implemented - see
http://www.postgresql.org/docs/current/static/functions-binarystring.html

=item *

Geometric functions are not implemented - see
http://www.postgresql.org/docs/current/static/functions-geometry.html

=item *

Network Address Functions are not implemented - see
http://www.postgresql.org/docs/current/static/functions-net.html

=back

=head1 EXTRAS

=head2 Stored Procedures

If the active database file contains a table called pglite_functions,
the module assumes that it will have the following structure:

  CREATE TABLE pglite_functions (
    name   TEXT,   -- name  of the function
    argnum INT,    -- number of arguments (-1 means any number)
    type   TEXT,   -- can be 'sql' or 'perl'
    sql    TEXT,   -- the body of the function
    PRIMARY KEY (name, argnum)
  );

In the case of a SQL-type function, it can contain syntax supported
through the module (and not directly by SQLite). The numeric arguments
($1-$9) customary in PostgreSQL are supported, so that in many cases
simple functions will be directly transferrable from pg_proc in a
PostgreSQL database.

An instance of a SQL snippet which would work as a function body both
in PostgreSQL and PgLite (e.g. with the function name
'full_price_descr'):

  SELECT TRIM(group_name||': '||price_description) 
    FROM price_group NATURAL JOIN price 
    WHERE price_id = $1

As for perl-type functions, the function body is simply the text of a
subroutine. Here is a simple example of a function body for the
function 'commify', which takes two arguments: the number to be
formatted and the desired number of decimal places:

  sub { 
    my ($num,$dp) = @_;
    my $format = "%.${dp}f";
    $num = scalar reverse(sprintf $format, $num);
    my $rest = $1 if $num =~ s/^(\d+)\.//;
    $num =~ s/(...)/$1,/g;
    $num = "$rest.$num" if $rest;
    return scalar reverse($num);
  }

=head2 Non-Pg Functions

=over

=item matches(), imatches(): 

These functions are used behind the scenes to implement support for
the '~' regex-matching operator and its variants. They take two
arguments, a string and a regular expression. matches() is case
sensitive, imatches() isn't.

=item matches_safe(), imatches_safe(): 

These work in the same way as matches() and imatches() except that
metacharacters are escaped in the regex argument. They are therefore
in many cases more suitable for user input and other untrusted
sources.

=item lower_latin1():

Depending on platform, lower() and upper() may not
transform the case of non-ascii characters despite a proper locale
being defined in the environment. This functions assumes that a
Latin-1 locale is active and returns a lower-case version of the input
given this assumption.

=item localeorder():

DBD::SQLite does not provide access to defining SQLite collation
functions. This is a workaround for a specific case where this
limitation can be an issue. Given a Latin-1 encoded string, it returns
a string of hex digits which can be ascii-sorted in the ordinary
way. The resulting row order will be in accordance with the currently
active locele - but only if the locale is Latin-1 based. The sort is
case-insensitive.

=item locale():

An information function simply returning the name of the current
locale. The module sets the locale based on the environment variables
$ENV{LC_COLLATE}, $ENV{LC_ALL}, $ENV{LANG}, and $ENV{LC_CTYPE}, in
that order. Currently it is not possible to use different locales for
character type and collation, as far as the module is concerned.

=back

=head2 DBD::PgLite::MirrorPgToSQLite

The companion module, DBD::PgLite::MirrorPgToSQLite, may be of use in
conjunction with this module. It can be used for easily mirroring
specific tables from a PostgreSQL database, moving views and (some)
functions as well if desired.


=head1 CAVEATS

Some functions defined by the module are not suitable for use with
UTF-8 data and/or in an UTF-8 locale. (This, however, would be rather
easy to change if you're willing to sacrifice proper support for 8-bit
locales such as iso-8859-1).

Please do not make the mistake of using this module for an important
production system - too much can go wrong. But as a development tool
it can be useful, and as a toy it can be fun...


=head1 TODO

There is a lot left undone. The next step is probably to handle
non-SELECT statements better.

=head1 SEE ALSO

DBI, DBD::SQLite, DBD::Pg, DBD::PgLite::MirrorPgToSQLite;

=head1 THANKS TO

Johan Vromans, for encouraging me to improve the sequence support.

=head1 AUTHOR

Baldur Kristinsson (bk@mbl.is), 2006.

 Copyright (c) 2006 Baldur Kristinsson. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.


=cut
