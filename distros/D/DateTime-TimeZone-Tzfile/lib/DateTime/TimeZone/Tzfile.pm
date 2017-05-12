=head1 NAME

DateTime::TimeZone::Tzfile - tzfile (zoneinfo) timezone files

=head1 SYNOPSIS

	use DateTime::TimeZone::Tzfile;

	$tz = DateTime::TimeZone::Tzfile->new(
		name => "local timezone",
		filename => "/etc/localtime");
	$tz = DateTime::TimeZone::Tzfile->new("/etc/localtime");

	if($tz->is_floating) { ...
	if($tz->is_utc) { ...
	if($tz->is_olson) { ...
	$category = $tz->category;
	$tz_string = $tz->name;

	if($tz->has_dst_changes) { ...
	if($tz->is_dst_for_datetime($dt)) { ...
	$offset = $tz->offset_for_datetime($dt);
	$abbrev = $tz->short_name_for_datetime($dt);
	$offset = $tz->offset_for_local_datetime($dt);

=head1 DESCRIPTION

An instance of this class represents a timezone that was encoded in a
file in the L<tzfile(5)> format.  These can express arbitrary patterns
of offsets from Universal Time, changing over time.  Offsets and change
times are limited to a resolution of one second.

This class implements the L<DateTime::TimeZone> interface, so that its
instances can be used with L<DateTime> objects.

=cut

package DateTime::TimeZone::Tzfile;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Date::ISO8601 0.000 qw(present_ymd);
use IO::File 1.13;
use IO::Handle 1.08;
use Params::Classify 0.000 qw(is_undef is_string is_ref);

our $VERSION = "0.010";

my $rdn_epoch_cjdn = 1721425;

# _fdiv(A, B), _fmod(A, B): divide A by B, flooring remainder
#
# B must be a positive Perl integer.  A must be a Perl integer.

sub _fdiv($$) {
	my($a, $b) = @_;
	if($a < 0) {
		use integer;
		return -(($b - 1 - $a) / $b);
	} else {
		use integer;
		return $a / $b;
	}
}

sub _fmod($$) { $_[0] % $_[1] }

=head1 CONSTRUCTOR

=over

=item DateTime::TimeZone::Tzfile->new(ATTR => VALUE, ...)

Reads and parses a L<tzfile(5)> format file, then constructs and returns
a L<DateTime>-compatible timezone object that implements the timezone
encoded in the file.  The following attributes may be given:

=over

=item B<name>

Name for the timezone object.  This will be returned by the C<name>
method described below, and will be included in certain error messages.

=item B<category>

The string or C<undef> that will be returned by the C<category> method
described below.  Default C<undef>.

=item B<is_olson>

The truth value that will be returned by the C<is_olson> method described
below.  Default false.

=item B<filename>

Name of the file from which to read the timezone data.  The filename
must be understood by L<IO::File>.

=item B<filehandle>

An L<IO::Handle> object from which the timezone data can be read.
This does not need to be a regular seekable file; it is read sequentially.
After the constructor has finished, the handle can still be used to read
any data that follows the timezone data.

=back

Either a filename or filehandle must be given.  If a timezone name is not
given, then the filename is used instead if supplied; a timezone name
must be given explicitly if no filename is given.

=item DateTime::TimeZone::Tzfile->new(FILENAME)

Simpler way to invoke the above constructor in the usual case.  Only the
filename is given; this will also be used as the timezone name.

=cut

sub _saferead($$) {
	my($fh, $len) = @_;
	my $data;
	my $rlen = $fh->read($data, $len);
	croak "can't read tzfile: $!" unless defined($rlen);
	croak "bad tzfile: premature EOF" unless $rlen == $len;
	return $data;
}

sub _read_u32($) { unpack("N", _saferead($_[0], 4)) }

sub _read_s32($) {
	my $uval = _read_u32($_[0]);
	return ($uval & 0x80000000) ? ($uval & 0x7fffffff) - 0x80000000 :
				      $uval;
}

sub _read_u8($) { ord(_saferead($_[0], 1)) }

my $unix_epoch_rdn = 719163;

sub _read_tm32($) {
	my $t = _read_s32($_[0]);
	return [ $unix_epoch_rdn + _fdiv($t, 86400), _fmod($t, 86400) ];
}

sub _read_tm64($) {
	my($fh) = @_;
	my $th = _read_s32($fh);
	my $tl = _read_u32($fh);
	my $dh = _fdiv($th, 86400);
	$th = (_fmod($th, 86400) << 10) | ($tl >> 22);
	my $d2 = _fdiv($th, 86400);
	$th = (_fmod($th, 86400) << 10) | (($tl >> 12) & 0x3ff);
	my $d3 = _fdiv($th, 86400);
	$th = (_fmod($th, 86400) << 12) | ($tl & 0xfff);
	my $d4 = _fdiv($th, 86400);
	$th = _fmod($th, 86400);
	my $d = $dh * 4294967296 + $d2 * 4194304 + (($d3 << 12) + $d4);
	return [ $unix_epoch_rdn + $d, $th ];
}

my $factory_abbr = "Local time zone must be set--see zic manual page";

sub new {
	my $class = shift;
	unshift @_, "filename" if @_ == 1;
	my $self = bless({}, $class);
	my($filename, $fh);
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "name") {
			croak "timezone name specified redundantly"
				if exists $self->{name};
			croak "timezone name must be a string"
				unless is_string($value);
			$self->{name} = $value;
		} elsif($attr eq "category") {
			croak "category value specified redundantly"
				if exists $self->{category};
			croak "category value must be a string or undef"
				unless is_undef($value) || is_string($value);
			$self->{category} = $value;
		} elsif($attr eq "is_olson") {
			croak "is_olson flag specified redundantly"
				if exists $self->{is_olson};
			$self->{is_olson} = !!$value;
		} elsif($attr eq "filename") {
			croak "filename specified redundantly"
				if defined($filename) || defined($fh);
			croak "filename must be a string"
				unless is_string($value);
			$filename = $value;
		} elsif($attr eq "filehandle") {
			croak "filehandle specified redundantly"
				if defined($filename) || defined($fh);
			$fh = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "file not specified" unless defined($filename) || defined($fh);
	unless(exists $self->{name}) {
		croak "timezone name not specified" unless defined $filename;
		$self->{name} = $filename;
	}
	unless(exists $self->{category}) {
		$self->{category} = undef;
	}
	unless(exists $self->{is_olson}) {
		$self->{is_olson} = !!0;
	}
	if(defined $filename) {
		($fh = IO::File->new($filename, "r")) && $fh->binmode
			or croak "can't read $filename: $!";
	}
	croak "bad tzfile: wrong magic number"
		unless _saferead($fh, 4) eq "TZif";
	my $fmtversion = _saferead($fh, 1);
	croak "bad tzfile: malformed version number"
		unless $fmtversion =~ /\A[2-9\0]\z/;
	_saferead($fh, 15);
	my($ttisgmtcnt, $ttisstdcnt, $leapcnt, $timecnt, $typecnt, $charcnt) =
		map { _read_u32($fh) } 1 .. 6;
	croak "bad tzfile: no local time types" if $typecnt == 0;
	my @trn_times = map { _read_tm32($fh) } 1 .. $timecnt;
	my @obs_types = map { _read_u8($fh) } 1 .. $timecnt;
	my @types = map {
		[ _read_s32($fh), !!_read_u8($fh), _read_u8($fh) ]
	} 1 .. $typecnt;
	my $chars = _saferead($fh, $charcnt);
	for(my $i = $leapcnt; $i--; ) { _saferead($fh, 8); }
	for(my $i = $ttisstdcnt; $i--; ) { _saferead($fh, 1); }
	for(my $i = $ttisgmtcnt; $i--; ) { _saferead($fh, 1); }
	my $late_rule;
	if($fmtversion ge "2") {
		croak "bad tzfile: wrong magic number"
			unless _saferead($fh, 4) eq "TZif";
		_saferead($fh, 16);
		($ttisgmtcnt, $ttisstdcnt, $leapcnt,
		 $timecnt, $typecnt, $charcnt) =
			map { _read_u32($fh) } 1 .. 6;
		croak "bad tzfile: no local time types" if $typecnt == 0;
		@trn_times = map { _read_tm64($fh) } 1 .. $timecnt;
		@obs_types = map { _read_u8($fh) } 1 .. $timecnt;
		@types = map {
			[ _read_s32($fh), !!_read_u8($fh), _read_u8($fh) ]
		} 1 .. $typecnt;
		$chars = _saferead($fh, $charcnt);
		for(my $i = $leapcnt; $i--; ) { _saferead($fh, 12); }
		for(my $i = $ttisstdcnt; $i--; ) { _saferead($fh, 1); }
		for(my $i = $ttisgmtcnt; $i--; ) { _saferead($fh, 1); }
		croak "bad tzfile: missing newline"
			unless _saferead($fh, 1) eq "\x0a";
		$late_rule = "";
		while(1) {
			my $c = _saferead($fh, 1);
			last if $c eq "\x0a";
			$late_rule .= $c;
		}
	}
	$fh = undef;
	for(my $i = @trn_times - 1; $i-- > 0; ) {
		unless(($trn_times[$i]->[0] <=> $trn_times[$i+1]->[0] ||
			$trn_times[$i]->[1] <=> $trn_times[$i+1]->[1]) == -1) {
			croak "bad tzfile: unsorted change times";
		}
	}
	my $first_std_type_index;
	my %offsets;
	for(my $i = 0; $i != $typecnt; $i++) {
		my $abbrind = $types[$i]->[2];
		croak "bad tzfile: invalid abbreviation index"
			if $abbrind > $charcnt;
		pos($chars) = $abbrind;
		$chars =~ /\G([^\0]*)/g;
		$types[$i]->[2] = $1;
		$first_std_type_index = $i
			if !defined($first_std_type_index) && !$types[$i]->[1];
		$self->{has_dst} = 1 if $types[$i]->[1];
		if($types[$i]->[0] == 0 && !$types[$i]->[1] &&
				$types[$i]->[2] eq "zzz") {
			# "zzz" means the zone is not defined at this time,
			# due for example to the location being uninhabited
			$types[$i] = "zone disuse";
		} else {
			$offsets{$types[$i]->[0]} = undef;
		}
	}
	unshift @obs_types,
		defined($first_std_type_index) ? $first_std_type_index : 0;
	foreach my $obs_type (@obs_types) {
		croak "bad tzfile: invalid local time type index"
			if $obs_type >= $typecnt;
		$obs_type = $types[$obs_type];
	}
	if(defined($late_rule) && $late_rule eq "<$factory_abbr>0" &&
			defined($obs_types[-1]) && $obs_types[-1]->[0] == 0 &&
			!$obs_types[-1]->[1] &&
			$obs_types[-1]->[2] eq $factory_abbr) {
		# This bizarre timezone abbreviation is used in the Factory
		# timezone in the Olson database.  It's not valid in a
		# SysV-style TZ value, because it contains spaces, but zic
		# puts it into one anyway because the file format demands
		# it.  DT:TZ:SystemV would object, so as a special
		# exception we ignore the TZ value in this case.
		$late_rule = undef;
	}
	if(defined $late_rule) {
		if($late_rule eq "") {
			$obs_types[-1] = "missing data";
		} elsif($late_rule =~
				/\A(?:zzz|<zzz>)[-+]?00?(?::00(?::00)?)?\z/) {
			$obs_types[-1] = "zone disuse";
		} else {
			require DateTime::TimeZone::SystemV;
			DateTime::TimeZone::SystemV->VERSION("0.009");
			$obs_types[-1] =
				DateTime::TimeZone::SystemV->new(
					system => $fmtversion ge "3" ?
							"tzfile3" : "posix",
					recipe => $late_rule);
		}
	}
	$self->{trn_times} = \@trn_times;
	$self->{obs_types} = \@obs_types;
	$self->{offsets} = [ sort { $a <=> $b } keys %offsets ];
	return $self;
}

sub _present_rdn_sod($$) {
	my($rdn, $sod) = @_;
	return sprintf("%sT%02d:%02d:%02d",
		present_ymd($rdn + $rdn_epoch_cjdn),
		int($sod/3600), int($sod/60)%60, $sod%60);
}

=back

=head1 METHODS

These methods are all part of the L<DateTime::TimeZone> interface.
See that class for the general meaning of these methods; the documentation
below only comments on the specific behaviour of this class.

=head2 Identification

=over

=item $tz->is_floating

Returns false.

=cut

sub is_floating { 0 }

=item $tz->is_utc

Returns false.

=cut

sub is_utc { 0 }

=item $tz->is_olson

Returns the truth value that was provided to the constructor for this
purpose, default false.  This nominally indicates whether the timezone
data is from the Olson database.  The files interpreted by this class
are very likely to be from the Olson database, but there is no explicit
indicator for this in the file, so this information must be supplied to
the constructor if required.

=cut

sub is_olson { $_[0]->{is_olson} }

=item $tz->category

Returns the value that was provided to the constructor for this purpose,
default C<undef>.  This is intended to indicate the general region
(continent or ocean) in which a geographical timezone is used, when
the timezone is named according to the hierarchical scheme of the Olson
timezone database.

=cut

sub category { $_[0]->{category} }

=item $tz->name

Returns the timezone name.  Usually this is the filename that was supplied
to the constructor, but it can be overridden by the constructor's B<name>
attribute.

=cut

sub name { $_[0]->{name} }

=back

=head2 Offsets

=over

=item $tz->has_dst_changes

Returns a truth value indicating whether any of the observances in the file
are marked as DST.  These DST flags are potentially arbitrary, and don't
affect any of the zone's behaviour.

=cut

sub has_dst_changes { $_[0]->{has_dst} }

#
# observance lookup
#

sub _type_for_rdn_sod {
	my($self, $utc_rdn, $utc_sod) = @_;
	my $lo = 0;
	my $hi = @{$self->{trn_times}};
	while($lo != $hi) {
		my $try = do { use integer; ($lo + $hi) / 2 };
		if(($utc_rdn <=> $self->{trn_times}->[$try]->[0] ||
		    $utc_sod <=> $self->{trn_times}->[$try]->[1]) == -1) {
			$hi = $try;
		} else {
			$lo = $try + 1;
		}
	}
	return $self->{obs_types}->[$lo];
}

sub _type_for_datetime {
	my($self, $dt) = @_;
	my($utc_rdn, $utc_sod) = $dt->utc_rd_values;
	$utc_sod = 86399 if $utc_sod >= 86400;
	my $type = $self->_type_for_rdn_sod($utc_rdn, $utc_sod);
	if(is_string($type)) {
		croak "time @{[_present_rdn_sod($utc_rdn, $utc_sod)]}Z ".
			"is not represented ".
			"in the @{[$self->{name}]} timezone ".
			"due to $type";
	}
	return $type;
}

=item $tz->offset_for_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it must
implement the C<utc_rd_values> method).  Returns the offset from UT that
is in effect at the instant represented by I<DT>, in seconds.

=cut

sub offset_for_datetime {
	my($self, $dt) = @_;
	my $type = $self->_type_for_datetime($dt);
	return is_ref($type, "ARRAY") ? $type->[0] :
		$type->offset_for_datetime($dt);
}

=item $tz->is_dst_for_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it must
implement the C<utc_rd_values> method).  Returns a truth value indicating
whether the timezone's observance at the instant represented by I<DT>
is marked as DST.  This DST flag is potentially arbitrary, and doesn't
affect anything else.

=cut

sub is_dst_for_datetime {
	my($self, $dt) = @_;
	my $type = $self->_type_for_datetime($dt);
	return is_ref($type, "ARRAY") ? $type->[1] :
		$type->is_dst_for_datetime($dt);
}

=item $tz->short_name_for_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it must
implement the C<utc_rd_values> method).  Returns the abbreviation
used to label the time scale at the instant represented by I<DT>.
This abbreviation is potentially arbitrary, and does not uniquely identify
either the timezone or the offset.

=cut

sub short_name_for_datetime {
	my($self, $dt) = @_;
	my $type = $self->_type_for_datetime($dt);
	return is_ref($type, "ARRAY") ? $type->[2] :
		$type->short_name_for_datetime($dt);
}

=item $tz->offset_for_local_datetime(DT)

I<DT> must be a L<DateTime>-compatible object (specifically, it
must implement the C<local_rd_values> method).  Takes the local
time represented by I<DT> (regardless of what absolute time it also
represents), and interprets that as a local time in the timezone of the
timezone object (not the timezone used in I<DT>).  Returns the offset
from UT that is in effect at that local time, in seconds.

If the local time given is ambiguous due to a nearby offset change,
the numerically lowest offset (usually the standard one) is returned
with no warning of the situation.  (Equivalently: the latest possible
absolute time is indicated.)  If the local time given does not exist
due to a nearby offset change, the method C<die>s saying so.

=cut

sub _local_to_utc_rdn_sod($$$) {
	my($rdn, $sod, $offset) = @_;
	$sod -= $offset;
	while($sod < 0) {
		$rdn--;
		$sod += 86400;
	}
	while($sod >= 86400) {
		$rdn++;
		$sod -= 86400;
	}
	return ($rdn, $sod);
}

sub offset_for_local_datetime {
	my($self, $dt) = @_;
	my($lcl_rdn, $lcl_sod) = $dt->local_rd_values;
	$lcl_sod = 86399 if $lcl_sod >= 86400;
	my %seen_error;
	foreach my $offset (@{$self->{offsets}}) {
		my($utc_rdn, $utc_sod) =
			_local_to_utc_rdn_sod($lcl_rdn, $lcl_sod, $offset);
		my $ttype = $self->_type_for_rdn_sod($utc_rdn, $utc_sod);
		if(is_string($ttype)) {
			$seen_error{$ttype} = undef;
			next;
		}
		my $local_offset = is_ref($ttype, "ARRAY") ? $ttype->[0] :
			eval { local $SIG{__DIE__};
				$ttype->offset_for_local_datetime($dt);
			};
		return $offset
			if defined($local_offset) && $local_offset == $offset;
	}
	my $error;
	foreach("zone disuse", "missing data") {
		if(exists $seen_error{$_}) {
			$error = $_;
			last;
		}
	}
	$error ||= "offset change";
	croak "local time @{[_present_rdn_sod($lcl_rdn, $lcl_sod)]} ".
		"does not exist in the @{[$self->{name}]} timezone ".
		"due to $error";
}

=back

=head1 SEE ALSO

L<DateTime>,
L<DateTime::TimeZone>,
L<DateTime::TimeZone::Olson>,
L<Time::OlsonTZ::Data>,
L<Time::OlsonTZ::Download>,
L<tzfile(5)>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2007, 2009, 2010, 2011, 2012, 2013
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
