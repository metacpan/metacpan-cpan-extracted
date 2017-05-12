# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;

our %cv;
our %CLASS;

our %force = (
	'cvGetWindowName' => 'Cv',
	'cvClone' => 'Cv',
	'cvFree' => 'Cv',
	'cvRelease' => 'Cv',
	'cvTypeOf' => 'Cv',
	);

sub parse_decl {
	local $_ = shift;
	s/\/\*.*\*\///sg;
	s/#\s*define.*[^\\]\n//sg;
	s/#\s*define[^\n]+//sg;
	s/\btypedef[^{]*{[^}]+}\s*\w+\s*;//sg;
	s/\btypedef[^;]+;//sg;
	s/\s+/ /sg;
	my %x;
	my $i = 1;
	# my $debug = /cvCvtColor/;
	my $debug = 0;
	print STDERR "parse_decl:1: $_\n" if $debug;
	while (s{([^\(=,;]+)\(((?:(?!\()(?!\)).)*)\)}{%$i}sg) {
		print STDERR "parse_decl:2: $_\n" if $debug;
		$x{$i++} = "$1($2)";
	}
	print STDERR "parse_decl:3: $_\n" if $debug;
	s/(%\d+)/$1;/g;
	print STDERR "parse_decl:4: $_\n" if $debug;
	my @decl;
	foreach my $decl (split(/[,;]/)) {
		1 while ($decl =~ s/%(\d+)/$x{$1}/g);
		print STDERR "parse_decl:5: $decl\n" if $debug;
		push(@decl, decl_cfunction($decl));
		hack_class($decl[-1]);
	}
	wantarray ? @decl : \@decl;
}

sub decl_cfunction {
	return undef unless (my $retval = shift) =~ s/\s*(\w[:\w]+)\s*\((.*)\)//s;
	my $name = $1; local $_ = $2;
	$retval =~ s/^\s+//s;
	$retval =~ s/\s+$//s;
	return undef unless $retval and $_;
	my @ST = ();
	push(@ST, [ $retval, $name ]);
	1 while (s/\(([^\(\)]*)\)/"\x02${ local $_ = $1; s{,}{;}g; \$_ }\x03"/ge);
	for (map { s/^\s+//; s/\s+$//; tr/\x02;\x03/(,)/; $_ } split(/,/)) {
		my ($init, $param);
		$init = $1 if s/\s*(=.*)$//;
		$param = $1 if s/\s*(\w+(\[[^\]]*\])?)$//;
		if ($param && $param ne 'void') {
			s/(\w)\s+(\w)/$1 $2/g;
			s/(\w|\*)\s+(\*)/$1$2/g;
			my @st = ($_, $param);
			push(@st, $init) if $init;
			push(@ST, \@st);
		}
	}
	$cv{$name} = \@ST;
}


sub hack_class {
	local $_ = shift;
	return undef unless $_;
	my $name = $_->[0]->[1];
	if ($CLASS{$name} = $force{$name}) {
		;
	} elsif (@{$_} == 1) {
		$CLASS{$name} = "Cv";
	} else {
		no warnings;
		my $type = ${${$_}[1]}[0];
		$type =~ s/^(IN)\s*//;
		$type =~ s/^(OUT|INOUT)\s*(.*)/$1\&/;

		if ($name =~ /^cvRelease/) {
			$type =~ s/\s*\*\s*\*$/\*\&/;
		} elsif ($name =~ /^cv.*Contour/) {
			if ($type =~ /CvContourScanner/) {
				$type =~ s/\s*\*$/\&/;
			}
		}

		if ($type =~ /^(const\s+)?(void|VOID)\*(\s*\&)?$/) {
			$CLASS{$name} = "Cv::Arr";
		} elsif ($type =~ /^(const\s+)?(Cv)(ContourScanner)(\s*\&)?$/) {
			$CLASS{$name} = "Cv::$3";
		} elsif ($type =~ /^(const\s+)?(void|VOID)\s*\*(\s*\&)?$/) {
			$CLASS{$name} = "Cv::Arr";
		} elsif ($type =~ /^(const\s+)?(Cv)(ContourScanner)(\s*\&)?$/) {
			$CLASS{$name} = "Cv::$3";
		} elsif ($type =~ /^(const\s+)?(Cv)(Point[\w\d]*)\s*\*(\s*\&)?$/) {
			$CLASS{$name} = "Cv";
		} elsif ($type =~ /^(const\s+)?(Cv|Ipl)(\w+)\s*\*(\s*\&)?$/) {
			$CLASS{$name} = "Cv::$3";
			if ($CLASS{$name}->can('dst')) {
				unless ($name =~ /Clone|Clear|Release/) {
					$CLASS{$name} = "Cv::Arr";
				}
			}
		} elsif ($type =~ /^(const\s+)?(\w+)(|\*|\*\*)$/) {
			$CLASS{$name} = "Cv";
		} else {
			my $args = @{$_} == 0 ? 'void' :
				join(', ', map { join(' ', @$_) } @{$_}[1..$#{$_}]);
			my $cproto = join(' ', @{${$_}[0]}), "($args)";
			ok(0, $cproto);
		}
	}
	return $CLASS{$name};
}

1;
