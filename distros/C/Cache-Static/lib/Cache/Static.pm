##
#
#    Copyright 2005-2006, Brian Szymanski
#
#    This file is part of Cache::Static
#
#    Cache::Static is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about Cache::Static, point a web browser at
#    http://chronicle.allafrica.com/scache/ or read the
#    documentation included with the Cache::Static distribution in the 
#    doc/ directory
#
##

package Cache::Static;
our $VERSION = '0.9905';

use strict;
use warnings;

use Storable;
use Digest::MD5 qw(md5_base64);
#allow serialization of code refs
$Storable::Deparse = 1;

our $ROOT = '/usr/local/Cache-Static';
our $LOGFILE = "$ROOT/log"; 
our $namespace = 'DEFAULT';

### LOG LEVELS:
#0 - no output
#1 - just hit/miss stats
#2 - hit/miss stats and critical errors (production)
#3 - his or miss and most error messages (development)
#4 - hit or miss and verbose error messages (debugging)
my @LOG_LEVEL_NAMES = qw ( NONE STAT CRIT WARN DEBUG );
### /LOG LEVELS
my @ILLEGAL_NAMESPACES = qw ( config log timestamps log_level );

#used to use a different root directory (used in TEST.pm)
sub _rebase {
	my $base = shift;
	$ROOT = $base;
	$LOGFILE = "$ROOT/log";
	_mkdir_p("$ROOT/DEFAULT/tmp");
	die "couldn't create DEFAULT namespace tmp directory: $@" if($@);
}

#fill %conf with some sane defaults
my %CONF = (
	DEFAULT => {
		dep_file_not_found_returns => 0,
		unrecognized_dependency_returns => 0,
		recursive_unlink => 0,
	},
	log_level => 3
);

#create the tmp directory for the default namespace
_mkdir_p("$ROOT/DEFAULT/tmp");
die "couldn't create DEFAULT namespace tmp directory: $@" if($@);
#create the timestamp directory if it doesn't exist
_mkdir_p("$ROOT/timestamps");
die "couldn't create timestamp directory: $@" if($@);

#read the global config
_readconf(); 
_log(3, "conf -- global config --");
_print_config();

sub _print_config {
	foreach my $c (keys %CONF) { 
		if(ref($CONF{$c})) {
			foreach my $cc (keys %{$CONF{$c}}) {
				_log(3, "conf($c): $cc = ".$CONF{$c}->{$cc});
			}
		} else {
			_log(3, "conf: $c = ".$CONF{$c});
		}
	} 
} 

#make sure the DEFAULT namespace's directories are there - we don't
#call init for these...
_mkdir_p("$ROOT/DEFAULT/tmp");
die "couldn't create DEFAULT namespace tmp directory: $@" if($@);

#just set the default namespace
sub init {
	_die_if_invalid_namespace($_[0]);
	$namespace = shift;
#
#	_mkdir_p("$ROOT/$namespace/tmp");
#	die "couldn't make/walk tmp directory: $ROOT/$namespace/tmp: $@" if($@);
#
#	#override conf with namespace-specific values
#	_readconf("$namespace") unless(defined($CONF{$namespace}));
#
#	_log(3, "conf --init--");
#	_print_config();
}

#determine whether we have fcntl and can use locking for native perl
#log writes (if not we fall back to invoking echo, which is slower and
#more error prone)
my $have_fcntl;
eval { 
	use Fcntl ':flock';
	$have_fcntl = 1;
}; if($@) {
	$have_fcntl = 0;
}

###########################
### glue for extensions ###
###########################
use Cache::Static::Configuration;
sub get_configuration_data {
	no strict 'refs';
	my $fh = *{ "Cache::Static::Configuration::DATA" };
	my $block = join ( '', <$fh> );
	my $conf = eval "{ $block }";
	return $conf->{$_[0]};
}

sub find_intersection {
	my ($ref1, $ref2) = @_;
	my (%h, @ret);
	foreach my $i (@$ref1, @$ref2) { $h{$i}++; };
	foreach my $e (keys %h) {
		push @ret, $e if($h{$e} == 2);
	}
	return @ret;
}

my @enabled_extensions = @{get_configuration_data("extensions")};
sub is_enabled {
	my $module = shift;
	return grep(/^$module$/i, @enabled_extensions);
}

my @POSSIBLE_HELPER_EXTENSIONS = find_intersection(\@enabled_extensions,
	[ qw ( HTML::Mason ) ] );
my @POSSIBLE_TIMESTAMP_EXTENSIONS = find_intersection(\@enabled_extensions,
	[ qw ( XML::Comma DBI ) ] );

my @helper_extensions;
foreach my $ext (@POSSIBLE_HELPER_EXTENSIONS) {
	eval "require $ext;";
	next if($@);
	my $util = $ext;
	$util =~ s/\:\:/_/g;
	eval "require Cache::Static::${util}_Util";
	if($@) {
		_log(2, "$ext exists but Cache::Static::${util}_Util does not\n");
	} else {
		push @helper_extensions, $ext;
	}
}

my @timestamp_extensions;
foreach my $ext (@POSSIBLE_TIMESTAMP_EXTENSIONS) {
	eval "require $ext;";
	next if($@);
	my $util = $ext;
	$util =~ s/\:\:/_/g;
	eval "require Cache::Static::${util}_Util";
	if($@) {
		_log(2, "$ext exists but Cache::Static::${util}_Util does not, disabling extension\n");
	} else {
		push @timestamp_extensions, $ext;
	}
}

sub _readconf {
	my $ns = shift;
	$ns = '' unless(defined($ns));
	_die_if_invalid_namespace($ns) if($ns);

	my $dir = "$ROOT/$ns";
	my @conf;
	open(CONF, "$dir/config") && 
	(@conf = map { my $t = $_; $t = lc($t); $t =~ s/^\s+//; $t =~ s/\s+$//;
		my $ar = []; @$ar = split(/\s+/, $t, 2); $ar } 
			grep(/^[^#]/, grep(/./, <CONF>)));
	close(CONF);
	foreach my $cr (@conf) { 
		if($cr->[0] eq 'log_level') {
			if(!$ns || $ns eq 'DEFAULT') {
				$CONF{log_level} = $cr->[1];
			} else {
				_log(3, "log_level directive in CONF($ns) ignored");
			}
		} else {
			$CONF{$ns ? $ns : 'DEFAULT'}->{$cr->[0]} = $cr->[1]; 
		}
	} 
}

#### useful when adding new modules
#warn "time: @timestamp_extensions\n";
#warn "help: @helper_extensions\n";
#die;

sub _has_timestamp {
	my $mod = shift;
	return grep(/^$mod$/, @timestamp_extensions);
}

sub _has_helper {
	my $mod = shift;
	return grep(/^$mod$/, @helper_extensions);
}

############################
### /glue for extensions ###
############################

#try to set up the logfile with lenient permissions
eval {
	open(FH, ">>$LOGFILE");
	close(FH);
	chmod 0666, $LOGFILE;
};

#number of levels of directory in cache
#TODO: move this to config file
my $CACHE_LEVELS = 3;

sub get_if_same {
### uncomment the below line to disable Cache::Static
#	return undef;
	my ($key, $depsref, %args) = @_;
	my ($ret, $dep) = _is_same($key, $depsref, %args);
	if($ret) {
		_log(1, "cache hit for key: $key");
		return _get($key, %args);
	} else {
		_log(1, "cache miss for key: $key on dep: $dep");
		return undef;
	}
}

sub _die_if_invalid_namespace {
	my $ns = shift;
	die "illegal namespace: $namespace" if($namespace =~ /\// ||
		grep (/^$namespace$/, @ILLEGAL_NAMESPACES));
}

sub set {
	my ($key, $content, $deps, %args) = @_;
	my $ns = $args{namespace} || $namespace;
	_die_if_invalid_namespace($ns);
	eval {
		#create any necessary directories
		my $dir = $key;
		$dir =~ s/\/[^\/]*$//;
		_mkdir_p("$ROOT/$ns/cache/$dir");
		die "couldn't make/walk directories: $@" if($@);

		#if we overrode the namespace, or if the dir got rm -rf'd out
		#from under us, this comes in handy...
		_mkdir_p("$ROOT/$ns/tmp");

		#write out the content
		my $tmpf = $key;
		$tmpf =~ s/\///g;
		open(FH, ">$ROOT/$ns/tmp/$tmpf") || die "couldn't open $ROOT/$ns/tmp/$tmpf: $!";
		(print FH $content) || die "couldn't print: $!";
		close(FH) || die "couldn't close: $!";
		chmod 0666, "$ROOT/$ns/tmp/$tmpf";

		#move the new cache file in place
		(rename "$ROOT/$ns/tmp/$tmpf", "$ROOT/$ns/cache/$key") ||
			die "couldn't rename content to $ROOT/$ns/cache/$key";

		if($deps) {
			#write out the deps
			my $frozen_deps = join('', map { $a=$_; $a.="\n"; $a } @$deps);
			open(FH, ">$ROOT/$ns/tmp/$tmpf.dep") || die "couldn't open: $!";
			(print FH $frozen_deps) || die "couldn't print: $!";
			close(FH) || die "couldn't close: $!";
			chmod 0666, "$ROOT/$ns/tmp/$tmpf.dep";

			#move the new .dep file in place
			(rename "$ROOT/$ns/tmp/$tmpf.dep", "$ROOT/$ns/cache/$key.dep") ||
				die "couldn't rename deps to $ROOT/$ns/cache/$key.dep: $!";
		}

	}; if($@) {
		_log(2, "Cache::Static::set couldn't save new value (in namespace: $ns) : $@");
	} else {
		_log(3, "Cache::Static::set refreshed $key in namespace: $ns");
	}
}

sub make_friendly_key {
	my ($url, $argsref) = @_;

	#key for Cache is url + args in deterministic order
	my $key = "$url?";
	foreach my $arg (sort keys %$argsref) {
		my $val = $argsref->{$arg};
		if(ref($val)) {
			if(ref($val) eq 'ARRAY') {
				$val = join("&$arg=", @$val);
			} elsif($val->isa('XML::Comma::Doc')
					&& _has_timestamp('XML::Comma')) {
				$val = "XML::Comma::Doc:".$val->doc_key;
			} else {
				_log(3, "got a ".ref($val)." and we're just freezing it...");
				$val = Storable::freeze($val);
			}
		}
		$key .= "$arg=$val&";
	}
	$key =~ s/&$//;

	#fix problem with friendly keys that have a multiple consecutive dashes,
	#as when they are printed in HTML debugging mode, they can cause SGML
	#comments to eat what is supposed to be code up to the next literal --
	#for one-to-one-ness, also map '-' (single dash) to '-1-'
	#this is really something browsers should work around, but don't. see:
	#  https://bugzilla.mozilla.org/show_bug.cgi?id=214476
	$key = join("", map { (/-+/) ? "-".length($_)."-" : $_ }
		split(/(-+)/, $key));

	return $key;
}

sub make_key {
	return md5_path(make_friendly_key(@_));
}

sub make_key_from_friendly {
	my $key = shift;
	return md5_path($key);
}

sub md5_path {
	my $key = shift;

	$key = md5_base64($key);
	# base64 is all alphanumeric except + and /
	# / must be translated
#	# + is translated for cosmetic reasons
	$key =~ s/\//_/g;
#	$key =~ s/\+/-/g;

	$key = join('/', grep(/./, split(/(.)/, $key, $CACHE_LEVELS+1)));

	return $key;
}

sub get_seconds_from_timespec {
	my $arg = shift;
	my @args = split(/([a-zA-Z])/, $arg);
	push @args, 's' if(($#args%2) == 0);
	my ($i, $period) = (0, 0);
	while($i < $#args) {
		my $n = $args[$i];
		my $c = $args[$i+1];
		my $mult;
		if(lc($c) eq 'w') { $mult = 7 * 24 * 60 * 60; }
		elsif(lc($c) eq 'd') { $mult = 24 * 60 * 60; }
		elsif(lc($c) eq 'h') { $mult = 60 * 60; }
		elsif(lc($c) eq 'm') { $mult = 60; }
		elsif(lc($c) eq 's') { $mult = 1; }
		else { 
			_log(2, "Cache::Static::get_seconds_from_timespec: unknown multiplier in $arg: $c");
			return undef;
		}
		$period += $n * $mult;
		$i += 2;
	}
	return $period;
}

sub _find_bound_before_time {
	my ($time, $offset, $bound) = @_;
	#valid bounds: [HMDW]
	my @lt = localtime($time);

	my ($roffset, $interval);
	#this would be much nicer with switch/case, grumble.
	if($bound eq 'M') {
		$roffset = $lt[0];
		$interval = 60;
	} elsif($bound eq 'H') {
		$roffset = $lt[0] + $lt[1] * 60;
		$interval = 60 * 60;
	} elsif($bound eq 'D') {
		$roffset = $lt[0] + $lt[1] * 60 + $lt[2] * 60 * 60;
		$interval = 24 * 60 * 60;
	} elsif($bound eq 'W') {
		$roffset = $lt[0] + $lt[1] * 60 + $lt[2] * 60 * 60 + 
			$lt[6] * 24 * 60 * 60;
		$interval = 7 * 24 * 60 * 60;
	} else {
		_log(2, "Cache::Static::_find_bound_before_time: unknown time boundary: $bound");
		return undef;
	}
	if($offset > $interval) {
		_log(2, "Cache::Static::_find_bound_before_time: offset ($offset) > interval ($interval)");
		return undef;
	}
	return $offset + $time - $roffset - ($roffset > $offset ? 0 : $interval);
}

sub _is_same {
	my ($key, $depsref, %args) = @_;
	my $ns = $args{namespace} || $namespace;
	_die_if_invalid_namespace($ns);

	#if no deps argument, find what we've got saved on disk for deps
	unless($depsref) {
		open(F, "$ROOT/$ns/cache/$key.dep");
		my $deps_str = <F>;
		close(F);
		my @deps = split(/\0/, $deps_str);
		$depsref = \@deps;
		_log(4, "Cache::Static::_is_same: got ".($#deps+1)." deps for $key");
	}

	#get last modified time of the cached version, or 0 if it doesn't exist
	my @t = stat("$ROOT/$ns/cache/$key");
	my $request_modtime = @t ? $t[9] : 0;
	return (0, "(not yet cached)") unless($request_modtime);

	# give a chance to add any module specific extra deps
	my %extra_deps;
### TODO: this is too slow, at least for XML::Comma (0.02 sec on p4@3GHz)
#	foreach my $dep (@$depsref) {
#		my ($type, $spec) = split(/\|/, $dep, 2);
#		my $dep_modtime;
#		if($type =~ /^_/) {
#			#not a builtin - call an extension
#			my ($module, $type, $spec) = split(/\|/, $dep, 3);
#			$module =~ s/^_//;
#			$module =~ s/\:\:/_/g;
#			my @deps = eval 
#				"Cache::Static::${module}_Util::get_extra_deps(\"$type\", \"$spec\")";
#			foreach my $d (@deps) {
#				$extra_deps{$d} = 1 unless($extra_deps{$d});
#			}
#		}
#	}
	my @deps = (@$depsref, keys %extra_deps);

	my @TRUE = ($key,1);
	foreach my $dep (@deps) {
		my @FALSE = (0,$dep);
		my ($full_type, $spec) = split(/\|/, $dep, 2);
		_log(4, "full_type: $full_type, spec: $spec");
		my ($type, $modifier) = split(/-/, $full_type, 2);
		if(defined($modifier)) {
			_log(4, "modifier found: full_type: $full_type, type: $type, modifier: $modifier");
		}
		my $dep_modtime;
		if($type =~ /^_/) {
			#not a builtin - call an extension
			my ($module, $type, $spec) = split(/\|/, $dep, 3);
			$module =~ s/^_//;
			$module =~ s/\:\:/_/g;

			_log(4, "here we are, extension, module: $module, type: $type spec: $spec");

			$dep_modtime = eval "Cache::Static::${module}_Util::modtime(\"$type\", \"$spec\")";
			if($@) {
				_log(3, "error calling Cache::Static::${module}_Util::modtime(\"$type\", \"$spec\"): $@");
			} elsif(!$dep_modtime) {
				_log(4, "got non-true value from Cache::Static::${module}_Util::modtime(\"$type\", \"$spec\"): $@ $!");
			}
		} elsif ($type eq 'file') {
			_log(4, "here we are, file spec: $spec");
			my @t = stat($spec);
			$dep_modtime = $t[9];
		} elsif ($type eq 'time') {
			my $spec_regex = '([0-9]*[hmdsw])+([0-9]*)?';
			if ($spec =~ /^[0-9]{10}$/) {
				#one-time timestamp expiration
				$dep_modtime = $spec;
			} elsif ($spec =~ /^$spec_regex$/) {
				#5w4d3h2m1s, e.g. 5 weeks, 4 days, ...
				#this is a bit backwards: now - spec > time of modification
				my $sex = get_seconds_from_timespec($spec);
				return @FALSE unless(defined($sex));
				$dep_modtime = time - $sex;
			} elsif ($spec =~ /^[HMDW]:$spec_regex$/) {
				#cron-esque timespecs, e.g. {week|day|hour|min} boundary + $spec
				#or 3:57 on day 3 of the week (W:3d3h57m)
				# bound_before(now)+offset <=> request time
				my ($bound, $offset) = split(/:/, $spec);
				my $sex = get_seconds_from_timespec($offset);
				return @FALSE unless(defined($sex));
				$dep_modtime = _find_bound_before_time(time,
					$sex, $bound);
				return @FALSE unless(defined($dep_modtime));
			} else {
				_log(2, "Cache::Static: unrecognized time spec: ($spec), regenerating");
				return @FALSE;
			}
		} elsif ($type eq 'HIT') {
			return @TRUE;
		} elsif ($type eq 'MISS') {
			return @FALSE;
		} else {
			my $ret = _get_conf($ns, 'unrecognized_dependency_returns');
			_log(2, "Cache::Static: unrecognized dependency ($type)".
				($ret ? ", serving anyway" : ", regenerating").
				" as specified by conf option unrecognized_dependency_returns");
			return ($ret ? @TRUE : @FALSE);
 		}
		#always override the default if modifier exists
		my $bool = defined($modifier) ? $modifier : 
			_get_conf($ns, 'dep_file_not_found_returns');
		return ($bool ? @TRUE : @FALSE) unless($dep_modtime);
		return @FALSE if($dep_modtime > $request_modtime);
	}
	return @TRUE;
}

sub _get_conf {
	my ($ns, $var) = @_;
	_readconf("$ns") unless(defined($CONF{$ns}));
	return $CONF{$ns}->{$var} || $CONF{DEFAULT}->{$var};
}

#TODO: this whole function is a race condition...
#is doing a regenerate if there was a change since _is_same best?
#or should we try to save the version we thought we were gonna use?
sub _get {
	my ($key, %args) = @_;
	my $ns = $args{namespace} || $namespace;
	_die_if_invalid_namespace($ns);

	open(FH, "$ROOT/$ns/cache/$key") || return undef;
	my $t = join('', <FH>);
	close(FH);

	_log(3, "Cache::Static::get read $key");

	return $t;
}

sub _write_spec_timestamp {
	my $spec = shift;
	_mkdirs_and_touch($ROOT.'/timestamps/'.md5_path($spec).'.ts', $spec);
}

sub _unlink_spec_timestamp {
	my $spec = shift;
	my $file = $ROOT.'/timestamps/'.md5_path($spec).'.ts';
	unlink($file);
	if(_get_conf($namespace, 'recursive_unlink')) {
		$file =~ s/\/[^\/]*$//;
		unless(opendir(DIR, $file)) {
			_log(3, "_unlink_spec_timestamp failed to opendir($file): (another process probably rmdir'd it):  $!");
			return;
		}
		my @files = readdir(DIR);
		closedir(DIR) if(@files);
		while($#files == 1 ) {
			unless(rmdir $file) {
				_log(3, "_unlink_spec_timestamp failed to rmdir($file): (another process probably touched a file in it): $!");
				return;
			}
			$file =~ s/\/[^\/]*$//;
			unless(opendir(DIR, $file)) {
				_log(3, "_unlink_spec_timestamp failed to opendir($file): (another process probably rmdir'd it):  $!");
				return;
			}
			my @files = readdir(DIR);
			closedir(DIR) if(@files);
		}
	}
}

#optional second argument indicates stuff to squirrel in the file
#TODO: the name is misleading given the possibility of the 2nd arg
sub _mkdirs_and_touch {
	my $file = shift;
	my $output = shift || '';

	#get rid of double slashes
	$file =~ s/\/\//\//g;

	#split the dir and the filename
	my $dir = $file;
	$dir =~ s/\/[^\/]*$//;

	my $err;
	eval {
		#mkdir -p
		_mkdir_p($dir);
		die "couldn't make/walk directories: $@" if($@);

		#touch/write to the file
		open(FH, ">$file") || die "couldn't open $file: $!";
		if($output) {
			print FH $output || die "couldn't print $output to $file: $!";
		}
		close(FH) || die "couldn't close $file: $!";
		chmod 0666, $file;
	}; if($@) {
		_log(2, "Cache::Static::_mkdirs_and_touch: couldn't update timestamps: $@");
	}
}

sub _log {
	my $severity = shift;
	return unless($severity <= $CONF{log_level});
	my $args = join(' ', @_);
	$args =~ s/\n/ /mg;
	$args =~ s/\s+$//;
	#we don't need a full stack trace at level 3
	#TODO: this regexp can be overly greedy
	$args =~ s/Stack:.*$//sg if($CONF{log_level} == 3);
	my @lt = localtime();
	$lt[4]++; #month starts at 0 for perl, 1 for humans
	@lt = map { sprintf("%02d", $_) } @lt;
	my $date = ($lt[5]+1900).'/'.$lt[4].'/'.$lt[3].' '.$lt[2].':'.$lt[1].':'.$lt[0];
	my $level = $LOG_LEVEL_NAMES[$severity];
	$level .= ' ' while(length($level) < 5);

	if($have_fcntl) {
		#TODO: we don't need to open/close every time.
		#just flock(LOG, LOCK_EX), seek, flock(LOG, LOCK_UN);
		#benchmark and safety test this...
		open(LOG, ">>$LOGFILE") || die "can't open log \"$LOGFILE\" $!";
		flock(LOG, LOCK_EX) || die "can't lock log \"$LOGFILE\" $!";
		seek(LOG, 0, 2); #seek to EOF if someone appended while we waited...
		print LOG "$level $date [$$] $args\n" || die "can't write to log \"$LOGFILE\": $!";
		#close does implicit unlock
		close(LOG) || die "can't close log \"$LOGFILE\": $!";
	} else {
		#TODO: there must be a way to escape " such that the shell doesn't puke
		$args =~ s/\"/'/g;
		`echo "$level $date [$$] $args" >>$LOGFILE`;
	}
}

sub _mkdir_p {
	my $dir = shift;
	my @dirs = grep (/./, split(/\//, $dir));
	my $dir_so_far = '/';
	foreach my $d (@dirs) {
		$dir_so_far .= "$d/";
		unless(-e $dir_so_far) {
			mkdir($dir_so_far) || die "couldn't create $dir_so_far: $!";
			chmod(0777, $dir_so_far) || die "couldn't change perms on $dir_so_far: $!";
		}
	}
}

1;
__END__


=head1 NAME

Cache::Static - Caching without freshness concerns

=head1 SYNOPSIS

=head2 HTML::Mason instructions

In handler.pl:
  use Cache::Static;

In any component you where you have a well defined set of
dependencies which change the output:

  <%init>
  my $_cs_deps = [
  #file dependencies - only regenerate if a file has changed
    'file|/path/to/some_configuration_file',

  #DBI dependencies - still under development - WONT WORK
  #DBI dependencies: note the third argument is a DSN
    '_DBI|table|mysql:scache_test_db|test_table',
    '_DBI|db|mysql:scache_test_db',

  #not yet implemented:
  #column level depends, e.g. "DBI|column|$dsn|$tablename|$columname"
  #row depends, e.g. "DBI|row|$dsn|$tablename|$uid_column_name|$uid_value"

  #XML::Comma dependencies - only regenerate if a Doc or Store has changed
    "_XML::Comma|Doc|$doc_key",
    "_XML::Comma|Store|$def|$store",

  #time dependencies (WARNING: these are discouraged, see doc/NOTE-time-deps)
    'time|15s', #every 15 seconds
    'time|M:15s', #every 15 seconds after the minute
    'time|H:2m', #every 2 minutes past the hour
    'time|W:2d3h5m0s', #every Tuesday at 3:05 AM

  #modifiers (indicate behavior when the file cannot be found)
    'file-0|/tmp/foo', #if ! -e /tmp/foo, regenerate
    'file-1|/tmp/foo', #if ! -e /tmp/foo, serve
    'file|/tmp/foo',   #use config value "dep_file_not_found_returns"

  #note modifiers also work on extensions, e.g.
    '_DBI-1|db|mysql:scache_test_db',
    '_XML::Comma-0|Store|mm_item|post',

  #etc... but modifiers CANNOT be used with times (since they have no
  #file backing on disk)
  ];

  #whatever you have in $_cs_deps above...
  return if Cache::Static::HTML_Mason_Util::cache_it($r, $m, 1, $_cs_deps);

  #...
  #rest of init block
  #...
  </%init>

=head2 Other Usage

TODO: an overview (and decent API) for usage outside of 
HTML::Mason land.

=head1 DESCRIPTION

  The guts of Cache::Static, in all its glory.
  
=head1 AUTHOR

  Brian Szymanski <scache@allafrica.com>

=head1 SEE ALSO

  http://chronicle.allafrica.com/scache/

=cut
