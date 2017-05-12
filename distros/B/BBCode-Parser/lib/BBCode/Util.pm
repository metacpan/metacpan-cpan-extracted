# $Id: Util.pm 284 2006-12-01 07:51:49Z chronos $
package BBCode::Util;
use base qw(Exporter);
use Carp qw(croak);
use HTML::Entities ();
use POSIX ();
use URI ();
use strict;
use warnings;

our $VERSION = '0.34';
our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS;

sub _export {
	my $sym = shift;
	$sym =~ s/^(?=\w)/&/;
	unshift @_, 'ALL';
	while(@_) {
		my $tag = shift;
		$EXPORT_TAGS{$tag} = [] unless exists $EXPORT_TAGS{$tag};
		push @{$EXPORT_TAGS{$tag}}, $sym;
	}
}

BEGIN { _export qw(pkgFilename pkg) }
sub pkgFilename($) {
	if($_[0] =~ /^((?:\w+::)*\w+)$/) {
		local $_ = $1;
		s#::#/#g;
		s/$/.pm/;
		return $_;
	}
	return undef;
}

my %userTags = (
	'BODY' => 'BBCode::Body',
);

BEGIN { _export qw(tagUserDefined tag) }
sub tagUserDefined($) {
	my $pkg = shift;
	my $file = pkgFilename($pkg);
	croak qq(Invalid package name "$pkg") unless defined $file;
	require $file;
	my $obj = bless {}, $pkg;
	croak qq(Package "$pkg" does not inherit from BBCode::Tag) unless UNIVERSAL::isa($obj,'BBCode::Tag');
	$userTags{uc($obj->Tag)} = $pkg;
}

BEGIN { _export qw(tagLoadPackage tag) }
sub tagLoadPackage($) {
	my($tag,$pkg);
	croak qq(Invalid tag name "$_[0]") unless $_[0] =~ m#^/?(_?\w+)$#;
	$tag = uc($1);
	if(exists $userTags{$tag}) {
		$pkg = $userTags{$tag};
	} else {
		$tag =~ s/^_/x/;
		$pkg = "BBCode::Tag::$tag";
	}
	my $file = pkgFilename($pkg);
	require $file;
	return $pkg;
}

BEGIN { _export qw(tagExists tag) }
sub tagExists($) {
	my $tag = shift;
	return 1 if eval {
		tagLoadPackage($tag);
		1;
	};
	return 0;
}

BEGIN { _export qw(tagCanonical tag) }
sub tagCanonical($) {
	local $_ = shift;
	if(ref $_) {
		return $_->Tag if UNIVERSAL::isa($_,'BBCode::Tag');
		croak qq(Invalid reference);
	} else {
		return uc($1) if /^(:\w+)$/;
		my $pkg = tagLoadPackage($_);
		return $pkg->Tag;
	}
}

BEGIN { _export qw(tagObject tag) }
sub tagObject($) {
	my $tag = shift;
	if(ref $tag) {
		return $tag if UNIVERSAL::isa($tag,'BBCode::Tag');
		croak qq(Invalid reference);
	} else {
		my $pkg = tagLoadPackage($tag);
		return bless {}, $pkg;
	}
}

BEGIN { _export qw(tagHierarchy tag) }
sub tagHierarchy($) {
	my $tag = tagCanonical(shift);
	return $tag if $tag =~ /^:/;
	my $pkg = tagLoadPackage($tag);
	return ($pkg->Tag, map { ":$_" } ($pkg->Class, 'ALL'));
}

BEGIN { _export qw(quoteQ quote) }
sub quoteQ($) {
	local $_ = $_[0];
	s/([\\'])/\\$1/g;
	return qq('$_');
}

BEGIN { _export qw(quoteQQ quote) }
sub quoteQQ($) {
	local $_ = $_[0];
	s/([\\"])/\\$1/g;
	return qq("$_");
}

BEGIN { _export qw(quoteBS quote) }
sub quoteBS($) {
	local $_ = $_[0];
	s/([\\\[\]"'=,\s\n])/\\$1/g;
	return $_;
}

BEGIN { _export qw(quoteRaw quote) }
sub quoteRaw($) {
	local $_ = $_[0];
	return undef if /[\\\[\]"'=,\s\n]/;
	return $_;
}

BEGIN { _export qw(quote quote) }
sub quote($) {
	my @q = sort {
		(length($a) <=> length($b)) or ($a cmp $b)
	} grep {
		defined $_
	} (quoteQ $_[0], quoteQQ $_[0], quoteBS $_[0], quoteRaw $_[0]);
	return $q[0];
}

BEGIN { _export qw(encodeHTML encode); }
sub encodeHTML($) {
	local $_ = $_[0];
	if(defined $_) {
		# Basic HTML/XML escapes
		s/&/&amp;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		s/"/&quot;/g;
		# &apos; is XML-only
		s/'/&#39;/g;
	}
	return $_;
}

BEGIN { _export qw(decodeHTML encode); }
sub decodeHTML($) {
	return HTML::Entities::decode($_[0]);
}

BEGIN { _export qw(parseBool parse) }
sub parseBool($) {
	local $_ = $_[0];
	return undef if not defined $_;
	return $_->as_bool() if ref $_ and UNIVERSAL::can($_, 'as_bool');
	return 1 if /^(?:
		1 |
		T | TR | TRU | TRUE |
		Y | YE | YES |
		ON
	)$/ix;
	return 0 if /^(?:
		0 |
		F | FA | FAL | FALS | FALSE |
		N | NO |
		OFF
	)$/ix;
	return $_ ? 1 : 0;
}

BEGIN { _export qw(parseInt parse) }
sub parseInt($) {
	my $num = shift;
	return undef if not defined $num;
	$num =~ s/[\s,_]+//g;
	$num =~ s/^\+//;
	return 0	if $num =~ /^-?$/;
	return 0+$1	if $num =~ /^ ( -? \d+ ) $/x;
	return undef;
}

BEGIN { _export qw(parseNum parse) }
sub parseNum($);
sub parseNum($) {
	my $num = shift;
	return undef if not defined $num;
	$num =~ s/[\s,_]+//g;
	if($num =~ /^ (.*) e (.*) $/ix) {
		my($m,$e) = ($1,$2);
		$m = parseNum $m;
		$e = parseNum $e;
 		return $m * (10 ** $e) if defined $m and defined $e;
		return undef;
 	}
	if($num =~ /^ ([^.]*) \. ([^.]*) $/x) {
		my($i,$f) = ($1,$2);
		$i = parseInt $i;
		return undef unless defined $i;
		return undef unless $f =~ /^(\d*)$/;
		$num = "$i.$f";
		$num =~ s/\.$//;
		return 0+$num;
	}
	return parseInt($num);
}

BEGIN { _export qw(parseEntity parse) }
sub parseEntity($);
sub parseEntity($) {
	local $_ = $_[0];
	return undef unless defined $_;
	s/^&(.*);$/$1/;
	s/^#([xob])/0$1/i;
	s/^#//;
	s/^U\+/0x/;

	my $ch;
	if(/^ 0x ([0-9A-F]+) $/xi) {
		$ch = hex($1);
	} elsif(/^ 0o ([0-7]+) $/xi) {
		$ch = oct($1);
	} elsif(/^ 0b ([01]+) $/xi) {
		my $b = ("\0" x 4) . pack("B*", $1);
		$ch = unpack "N", substr($b, -4);
	} elsif(/^ 0 ([0-7]{3}) $/x) {
		$ch = oct($1);
	} elsif(/^ (\d+) $/x) {
		$ch = 0+$1;
	}
	return sprintf "#x%X", $ch if defined $ch;

	my $decoded = HTML::Entities::decode("&$_;");
	return undef if $decoded eq "&$_;";
	return $_;
}

BEGIN { _export qw(parseListType parse) }
my %listtype = (
	'*'		=> [ qw(ul) ],
	'1'		=> [ qw(ol decimal) ],
	'01'	=> [ qw(ol decimal-leading-zero) ],
	'A'		=> [ qw(ol upper-latin) ],
	'a'		=> [ qw(ol lower-latin) ],
	'I'		=> [ qw(ol upper-roman) ],
	'i'		=> [ qw(ol lower-roman) ],
	"\x{3B1}"	=> [ qw(ol lower-greek) ],
	"\x{5D0}"	=> [ qw(ol hebrew) ],
	"\x{3042}"	=> [ qw(ol hiragana) ],
	"\x{3044}"	=> [ qw(ol hiragana-iroha) ],
	"\x{30A2}"	=> [ qw(ol katakana) ],
	"\x{30A4}"	=> [ qw(ol katakana-iroha) ],
);
sub parseListType($) {
	local $_ = $_[0];
	my @ret;
	if(defined $_) {
		if(/^(disc|circle|square|none)$/i) {
			@ret = ('ul', lc $1);
		} elsif(/^(
			decimal(?:-leading-zero)? |
			(?:upper|lower)-(?:roman|latin|alpha) |
			lower-greek |
			hebrew |
			georgian |
			armenian |
			cjk-ideographic |
			(?:hiragana|katakana)(?:-iroha)?
		)$/ix) {
			@ret = ('ol', lc $1);
		} elsif(exists $listtype{$_}) {
			@ret = @{$listtype{$_}};
		}
	}
	return @ret;
}

# Conversion factors from CSS units to points
my %conv = (
	# Integer conversions within English units
	pt	=> 1,
	pc	=> 12,
	in	=> 72,

	# Floating-point conversions from Metric units
	mm	=> 72/25.4,
	cm	=> 72/2.54,

	# Somewhat approximate, but the CSS standard is actually rather
	# picky about how many pixels a 'pixel' is at different resolutions,
	# so this is actually relatively reliable.
	px	=> 0.75,
);

# Emulation of <font size="num">...</font> from HTML 3.2
# See <URL:http://www.w3.org/TR/CSS21/fonts.html#font-size-props>
# Tweaked slightly to be more logical
my @compat = qw(xx-small x-small small medium large x-large xx-large 300%);

BEGIN { _export qw(parseFontSize parse) }
sub parseFontSize($;$$$);
sub parseFontSize($;$$$) {
	local $_ = shift;
	return undef unless defined $_;
	my($base,$lo,$hi) = @_;
	$base = 12 if not defined $base;
	$lo = 8 if not defined $lo;
	$hi = 72 if not defined $hi;
	s/\s+/ /g;
	s/^\s|\s$//g;

	# CSS 2.1 15.7 <absolute-size>
	if(/^( (?:xx?-)? (?:large|small) | medium )$/ix) {
		return lc $1;
	}

	# CSS 2.1 15.7 <relative-size>
	# Note: Since [FONT] is nestable and not readily computable before HTML
	#		rendering, this can allow a malicious user to escape the
	#		admin-defined font size limits
	if(/^ ( larger | smaller ) $/ix) {
		return lc $1;
	}

	# CSS 2.1 4.3.2 <length>
	if(/^ ( [\s\d._+-]+ ) ( [a-z]+ ) $/ix) {
		my($n,$unit) = ($1,lc $2);
		$n = parseNum $n;
		if(defined $n and $n > 0) {
			my $conv;
			if(exists $conv{$unit}) {
				$conv = $conv{$unit};
			} elsif($unit =~ /^em$/i) {
				$conv = $base;
			} elsif($unit =~ /^ex$/i) {
				$conv = $base * 0.5;
			} else {
				return undef;
			}
			my $n2 = $n * $conv;
			if(defined $lo and $n2 < $lo) {
				$n = $lo / $conv;
			} elsif(defined $hi and $n2 > $hi) {
				$n = $hi / $conv;
			}
			$n = sprintf "%.3f", $n;
			$n =~ s/0+$//;
			$n =~ s/\.$//;
			return "$n$unit";
		} else {
			return undef;
		}
	}

	# CSS 2.1 4.3.3 <percentage>
	# Note: The same concerns apply as for <relative-size>
	if(/^ ( [\s\d._+-]+ ) % $/x) {
		my $n = parseNum $1;
		if(defined $n and $n > 0) {
			$n *= 0.01;
			my $n2 = $n * $base;
			if(defined $lo and $n2 < $lo) {
				$n = $lo / $base;
			} elsif(defined $hi and $n2 > $hi) {
				$n = $hi / $base;
			}
			$n *= 100;
			$n = sprintf "%.3f", $n;
			$n =~ s/0+$//;
			$n =~ s/\.$//;
			return "$n%";
		} else {
			return undef;
		}
	}

	# HTML 3.2 <font size="number">
	# See <URL:http://www.w3.org/TR/REC-html32#font>
	if(/^ (\d+) $/x) {
		my $n = 0+$1;
		if($n >= 0 and $n < @compat) {
			return $compat[$n];
		} else {
			return parseFontSize("$n pt",$base,$lo,$hi);
		}
	}

	# HTML 3.2 <font size="+number">
	if(/^ \+ (\d+) $/x) {
		# "+1" is roughly equivalent to CSS 2.1 "larger"
		my $n = sprintf "%f%%", 100 * (1.25 ** $1);
		return parseFontSize($n,$base,$lo,$hi);
	}

	# HTML 3.2 <font size="-number">
	if(/^ - (\d+) $/x) {
		# "-1" is roughly equivalent to CSS 2.1 "smaller"
		my $n = sprintf "%f%%", 100 * (0.85 ** $1);
		return parseFontSize($n,$base,$lo,$hi);
	}

	return undef;
}

# Official CSS 2.1 colors are passed through as-is
my %cssColor = map { $_ => 1 } qw(
	maroon red orange yellow olive
	purple fuchsia white lime green
	navy blue aqua teal
	black silver gray
);

# Other named colors must map to an official named color or an #RRGGBB color
my %extraColor = (
	darkred		=> 'maroon',
	darkblue	=> 'navy',
);

BEGIN { _export qw(parseColor parse) }
sub parseColor($) {
	local $_ = $_[0];
	return undef unless defined $_;
	s/\s+//g;
	$_ = lc $_;

	return $1 if /^(\w+)$/ and exists $cssColor{$1};
	return $extraColor{$_} if exists $extraColor{$_};

	if(s/^#//) {
		s/^ ( [0-9a-f]{1,2} ) $/$1$1$1/x;
		s/^ ([0-9a-f]) \1 ([0-9a-f]) \2 ([0-9a-f]) \3 $/$1$2$3/x;

		return "#$_" if /^ [0-9a-f]{3} $/x;
		return "#$_" if /^ [0-9a-f]{6} $/x;
	} else {
		return $1 if /^( rgb \( (?: \d+ , ){2} \d+ \) )$/x;
		return $1 if /^( rgba\( (?: \d+ , ){3} \d+ \) )$/x;
		return $1 if /^( rgb \( (?: \d+% , ){2} \d+% \) )$/x;
		return $1 if /^( rgba\( (?: \d+% , ){3} \d+% \) )$/x;
	}
	return undef;
}

sub _url_parse_opaque($) {
	local $_ = $_[0];
	my @ret = (undef) x 3;

	$ret[2] = $1	if s/(#.*)$//;
	$ret[0] = lc $1	if s/^([\w+-]+)://;
	$ret[1] = $_;

	return @ret if wantarray;
	return \@ret;
}

sub _url_parse_query($) {
	local $_ = $_[0];
	my @ret = (undef) x 2;

	$ret[1] = $1 if s/(\?.*)$//;
	$ret[0] = $_;

	return @ret if wantarray;
	return \@ret;
}

sub _url_parse_path($) {
	local $_ = $_[0];
	my @ret = (undef) x 2;

	if(s#^//##) {
		$ret[0] = $1 if s#^([^/]+)##;
		s#^$#/#;
		$ret[1] = $_;
	} elsif(m#^/#) {
		$ret[1] = $_;
	} else {
		return () if wantarray;
		return undef;
	}

	return @ret if wantarray;
	return \@ret;
}

sub _url_parse_server($) {
	local $_ = $_[0];
	my($userpass,$hostport);

	if(/^ ([^@]*) \@ ([^@]*) $/x) {
		($userpass,$hostport) = ($1,$2);
	} else {
		$hostport = $_;
	}

	my @ret = (undef) x 4;

	$_ = $userpass;
	if(defined $_) {
		if(/^ ([^:]*) : ([^:]*) $/x) {
			@ret[0,1] = ($1,$2);
		} else {
			$ret[0] = $_;
		}
	}

	$_ = $hostport;
	if(s/:(\d+)$//) {
		$ret[3] = $1;
	} elsif(s/:([\w+-]+)$//) {
		$ret[3] = getservbyname($1,'tcp');
		goto Failure if not defined $ret[3];
	} else {
		s/:$//;
	}

	s/\.*$/./;
	if(/^ ( (?: [\w-]+ \. )+ ) $/x) {
		$ret[2] = $1;
		$ret[2] =~ s/\.$//;
	}

	goto Failure if not defined $ret[2];
	return @ret if wantarray;
	return \@ret;

Failure:
	return () if wantarray;
	return undef;
}

my %urltype = (
	'http'		=> 3,
	'https'		=> 3,
	'ftp'		=> 3,

	'file'		=> 2,

	'mailto'	=> 1,

	'data'		=> 0,
	'javascript' => 0,
);

sub _url_parse($$) {
	my($str,$schemes) = @_;

	my($scheme,$opaque,$fragment) = _url_parse_opaque($str);
	return undef unless defined $scheme;
	return undef unless exists $urltype{$scheme};

	if($urltype{$scheme} > 0) {
		my($rest,$query) = _url_parse_query($opaque);

		if($urltype{$scheme} > 1) {
			my($auth,$path) = _url_parse_path($rest);
			return undef unless defined $path;

			if($urltype{$scheme} > 2) {
				return undef unless defined $auth;
				my($user,$pass,$host,$port) = _url_parse_server($auth);
				return undef unless defined $host;

				$auth = '';
				if(defined $user) {
					$auth .= $user;
					$auth .= ':'.$pass if defined $pass;
					$auth .= '@';
				}
				$auth .= $host;
				$auth .= ':'.$port if defined $port;
			}

			$rest = join '', map { defined $_ ? $_ : '' } ('//',$auth,$path);
		}

		$opaque = join '', map { defined $_ ? $_ : '' } ($rest,$query);
	}
	$str = $scheme.':'.$opaque.(defined $fragment ? $fragment : '');

	my $url = URI->new_abs($str, 'http://sanity.check.example.com/')->canonical;
	return undef unless defined $url->scheme;
	return undef unless exists $$schemes{$url->scheme};
	return undef if $url->as_string =~ /\bsanity\.check\.example\.com\b/i;
	return undef if $url->can('userinfo') and defined $url->userinfo;
	return undef if $url->can('host') and not defined $url->host;
	if($url->scheme eq 'mailto') {
		my %unsafe = $url->headers;
		my %safe;
		foreach my $key (keys %unsafe) {
			if($key =~ /^(?:to|cc|bcc)$/i) {
				my @to = split /,/, $unsafe{$key};
				$key = lc $key;
				foreach(@to) {
					if(/^ ( [\w.+-]+ \@ (?: \w[\w-]*(?<=\w) \. )+ [a-z]{2,6} ) $/xi) {
						if(exists $safe{$key}) {
							$safe{$key} .= ",$1";
						} else {
							$safe{$key} = $1;
						}
					}
				}
				next;
			}
			if($key =~ /^subject$/i) {
				if($unsafe{$key} =~ /^ ( [\x20-\x7E]+ ) $/x) {
					$safe{subject} = $1;
				}
				next;
			}
		}
		return undef unless exists $safe{to};
		$url->headers(%safe);
	}
	return $url;
}

BEGIN { _export qw(parseURL parse) }
my %schemes = map { $_ => 1 } qw(http https ftp mailto data);
sub parseURL($) {
	foreach('%', 'http://%', 'mailto:%') {
		my $str = $_;
		$str =~ s/%/$_[0]/g;
		my $url = _url_parse($str, \%schemes);
		return $url if defined $url;
	}
	return undef;
}

BEGIN { _export qw(parseMailURL parse) }
my %mail_schemes = (mailto => 1);
sub parseMailURL($) {
	foreach('%', 'mailto:%') {
		my $str = $_;
		$str =~ s/%/$_[0]/g;
		my $url = _url_parse($str, \%mail_schemes);
		return $url if defined $url;
	}
	return undef;
}

BEGIN { _export qw(multilineText text) }
sub multilineText {
	if(defined wantarray) {
		my $str = join "", @_;
		return $str unless wantarray;
		return split /(?<=\n)/, $str;
	}
}

BEGIN { _export qw(textURL text) }
sub textURL($) {
	my $url = shift;
	$url = parseURL($url) if not ref $url;
	return undef if not defined $url;
	if($url->scheme eq 'mailto') {
		return $url->to;
	}
	if($url->scheme eq 'http' or $url->scheme eq 'https') {
		if(not defined $url->query or $url->query eq '') {
			if($url->path eq '' or $url->path eq '/') {
				return $url->host;
			}
			return $url->host.$url->path;
		}
	}
	if($url->scheme eq 'ftp') {
		return $url->path.' on '.$url->host.' (FTP)';
	}
	if($url->scheme eq 'data') {
		my $m = $url->media_type;
		if(defined $m) {
			$m =~ s/;.*$//;
			return "Inline data ($m)";
		}
		return "Inline data";
	}
	return $url->as_string;

}

BEGIN { _export qw(textALT text) }
sub textALT($) {
	my $url = shift;
	$url = parseURL($url) if not ref $url;
	return undef if not defined $url;
	if($url->scheme eq 'data') {
		return "[Inline data]";
	}
	my $path = $url->path;
	$path =~ s#^.*/##;
	return "[$path]";
}

sub _b10_len($) {
	my $n = shift;
	if($n > 0) {
		return 1+POSIX::floor(log($n)/log(10));
	}
	if($n < 0) {
		return 2+POSIX::floor(log(-$n)/log(10));
	}
	return 1;
}

sub _max {
	my $max;
	while(@_) {
		my $val = shift;
		$max = $val if defined $val and (not defined $max or $val > $max);
	}
	return $max;
}

BEGIN { _export qw(createListSequence) }
sub createListSequence($;$$) {
	my($type,$start,$total) = @_;
	my @list = parseListType($type);
	$start = 1 unless defined $start;

	if(@list and $list[0] eq 'ol') {
		my $type = (@list > 1) ? $list[1] : 'decimal';

		if(0) {
			# Disabled until the generators can be split into separate packages
			if($type =~ /^(upper|lower)-(alpha|latin|roman|greek)$/i) {
				my $func = 'textOrder'.ucfirst(lc($2));
				my $uc = $1 =~ /^upper$/i;
				$func =~ s/Latin$/Alpha/;
				{
					no strict 'refs';
					$func = \&{$func};
				}
				if($uc) {
					return sub { $func->($start++).'.' };
				} else {
					return sub { lc $func->($start++).'.' };
				}
			}
			if($type =~ /^(hiragana|katakana)(?:-(iroha))?$/i) {
				my $func = 'textOrder'.ucfirst(lc($1)).(defined $2 ? uc($2) : '');
				{
					no strict 'refs';
					$func = \&{$func};
				}
				return sub { $func->($start++).'.' };
			}
			if($type =~ /^cjk-ideographic$/i) {
				return sub { textOrderCJK($start++).'.' };
			}
			if($type =~ /^hebrew$/i) {
				return sub { textOrderHebrew($start++).'.' };
			}
			if($type =~ /^georgian$/i) {
				return sub { textOrderGeorgian($start++).'.' };
			}
			if($type =~ /^armenian$/i) {
				return sub { textOrderArmenian($start++).'.' };
			}
		}

		if($type =~ /^decimal-leading-zero$/i) {
			if(defined $total) {
				my $end = $total + $start - 1;
				my $len = _max 3, 1+_b10_len(abs $start), 1+_b10_len(abs $end);
				my $fmt = sprintf '%% 0%dd.', $len;
				return sub { sprintf($fmt,$start++) };
			} else {
				return sub { sprintf("% 03d.", $start++) };
			}
		}

		if(defined $total) {
			my $end = $total + $start - 1;
			my $len = _max _b10_len $start, _b10_len $end;
			my $fmt = sprintf '%%%dd.', $len;
			return sub { sprintf($fmt,$start++) };
		} else {
			return sub { sprintf("%d.",$start++) };
		}
	}
	return sub { '*' };
}

BEGIN {
	push @EXPORT_OK, @{$EXPORT_TAGS{ALL}} if exists $EXPORT_TAGS{ALL};
	push @EXPORT, @{$EXPORT_TAGS{DEFAULT}} if exists $EXPORT_TAGS{DEFAULT};
}

1;
