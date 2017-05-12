#!/usr/bin/perl
# -*- mode: perl; coding: utf-8; tab-width: 4 -*-

use strict;

use IO::File;
use File::Basename;
use File::Find;
use Data::Dumper;

use Getopt::Long;
my %opts;

GetOptions (
	"dump=s@"    => \$opts{dump},
	"tex"        => \$opts{tex},
	"html"       => \$opts{html},
	"rst"        => \$opts{rst},
	"packages=s@" => \$opts{packages},
	"verbose+"   => \$opts{verbose},
	);

our %cv;
our $CV_VERSION = undef;
our %file;

if ($opts{html}) {
	find(sub { parse_htm($_) if /\.htm$/;
			   parse_ver($_) if /version\.hpp$|cvver\.h$/;
		 }, @ARGV); # OpenCV-1
} elsif ($opts{tex}) {
	find(sub { parse_tex($_) if /\.tex$/;
			   parse_ver($_) if /version\.hpp$|cvver\.h$/;
		 }, @ARGV); # OpenCV-2.[0-2]
} else {
	find(sub { parse_rst($_) if /\.rst$/;
			   parse_ver($_) if /version\.hpp$|cvver\.h$/;
		 }, @ARGV); # OpenCV-2.[3-4]
}

# print STDERR "version = $CV_VERSION\n";

if ($CV_VERSION =~ /^2\.[0-2]/) {

	$cv{cvSampleLine} = [
		[ 'int', 'cvSampleLine' ],
		[ 'const CvArr*', 'image' ],
		[ 'CvPoint', 'pt1' ],
		[ 'CvPoint', 'pt2' ],
		[ 'void*', 'buffer' ],
		[ 'int', 'connectivity', '=8' ],
		];

	$cv{cvImgToObs_DCT} = [
		[ 'void', 'cvImgToObs_DCT' ],
		[ 'IplImage*', 'image' ],
		[ 'float*', 'obs' ],
		[ 'CvSize', 'dctSize' ],
		[ 'CvSize', 'obsSize' ],
		[ 'CvSize', 'delta' ],
		];

	$cv{cvGoodFeaturesToTrack} = [
	    [ 'void', 'cvGoodFeaturesToTrack' ],
	    [ 'const CvArr*', 'image' ],
	    [ 'CvArr*', 'eig_image' ],
	    [ 'CvArr*', 'temp_image' ],
	    [ 'CvPoint2D32f*', 'corners' ],
	    [ 'int*', 'corner_count' ],
	    [ 'double', 'quality_level' ],
	    [ 'double', 'min_distance' ],
	    [ 'const CvArr*', 'mask', '=NULL' ],
	    [ 'int', 'block_size', '=3' ],
	    [ 'int', 'use_harris', '=0' ],
	    [ 'double', 'k', '=0.04' ],
		];

}

if ($CV_VERSION =~ /^2\.[1-3]/) {

	$cv{cvGetHistValue_1D} = [
		[ 'float*', 'cvGetHistValue_1D' ],
		[ 'CvHistogram*', 'hist' ],
		[ 'int', 'idx0' ],
		];
	$cv{cvGetHistValue_2D} = [
		[ 'float*', 'cvGetHistValue_2D' ],
		[ 'CvHistogram*', 'hist' ],
		[ 'int', 'idx0' ],
		[ 'int', 'idx1' ],
		];
	$cv{cvGetHistValue_3D} = [
		[ 'float*', 'cvGetHistValue_3D' ],
		[ 'CvHistogram*', 'hist' ],
		[ 'int', 'idx0' ],
		[ 'int', 'idx1' ],
		[ 'int', 'idx2' ],
		];
	$cv{cvGetHistValue_nD} = [
		[ 'float*', 'cvGetHistValue_nD' ],
		[ 'CvHistogram*', 'hist' ],
		[ 'int', 'idx[]' ],
		];
}

my %RENAME = (
	cvSize2D23f => q(cvSize2D32f),
	);

if ($opts{dump}) {
	if (@{$opts{dump}} == 1 &&
		${$opts{dump}}[0] =~ /^(full|all|yes)/i) {
		print Data::Dumper->Dump([\%cv, \%file], [qw(*cv *file)]);
	} else {
		print Data::Dumper->Dump([ $cv{$_} ], ["\$cv{$_}"])
			for (@{$opts{dump}});
	}
	print "1;\n";
} else {
	foreach (sort { $a->[0]->[1] cmp $b->[0]->[1] } values %cv) {
		my $args = @{$_}?
			join(', ', map { join(' ', @$_) } @{$_}[1..$#{$_}]) : 'void';
		print join(' ', @{${$_}[0]}), "($args)", "\n";
	}
}
							 
exit 0;


sub parse_ver {
	my $name = shift;
	return unless my $file = IO::File->new($name);
	my %v;
	while (<$file>) {
		if (/\#define\s+(CV_(MAJOR|MINOR|SUBMINOR)_VERSION)\s+(\d+)/) {
			$v{$2} = $3;
		}
	}
	$CV_VERSION = "$v{MAJOR}.$v{MINOR}.$v{SUBMINOR}";
}

sub parse_htm {
	my $name = shift;
	return unless my $file = IO::File->new($name);
	my $cvfunc;
	my @pre;
	while (<$file>) {
		if (/\bname\s*=\s*"decl_(cv\w+)"/) {
			$cvfunc = $1;
		}
		if (/<pre>/ .. /<\/pre>/) {
			next unless $cvfunc;
			push(@pre, $_);
			next unless $& eq "<\/pre>";
			if (join('', @pre) =~ /<pre>(.*)<\/pre>/s) {
				# parse_decl($1);
				$file{$name}{$_->[0]->[1]} = $_ for parse_decl($1);
			}
			@pre = ();
			$cvfunc = undef;
		}
	}
}

sub parse_tex {
	my $name = shift;
	return unless my $file = IO::File->new($name);
	my @lines;
	while (<$file>) {
		s/[\\\/](par|newline)/ /sg;
		s/\\([\#_])/$1/g;
		s/\s+/ /g;
		if (/\\cvexp{/ .. /}/) {
			push(@lines, $_);
			next unless $& eq "}";
			if (join('', @lines) =~ /\\cvexp{([^}]*)}/s) {
				parse_decl($1);
			}
			@lines = ();
		}
		if (/\\cvdefC{/ .. /}/) {
			push(@lines, $_);
			next unless $& eq "}";
			if (join('', @lines) =~ /\\cvdefC{([^}]*)}/s) {
				# parse_decl($1);
				$file{$name}{$_->[0]->[1]} = $_ for parse_decl($1);
			}
			@lines = ();
		}
	}
}

sub parse_rst {
	my $name = shift;
	return unless my $file = IO::File->new($name);
	my @cfunctions; my %param;
	# local $/ = "\n\n";
	while (<$file>) {
		if (/^\s*$/) {
			;
		} elsif (/^\.\. ocv:cfunction::(.*)/) {
			# parse_decl($1);
			$file{$name}{$_->[0]->[1]} = $_ for parse_decl($1);
		}
	}
}

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
	# my $debug = /(Get|Query)HistValue/;
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
		if (my $d = decl_cfunction($decl)) {
			push(@decl, $d);
		}
	}
	wantarray? @decl : \@decl;
}

sub decl_cfunction {
	return undef unless (my $retval = shift) =~ s/\s*(\w[:\w]+)\s*\((.*)\)//s;
	my $name = $1; local $_ = $2;
	$retval =~ s/^\s+//s;
	$retval =~ s/\s+$//s;
	return undef unless $retval and $_;
	my @ST = ();
	if (my $ren = $RENAME{$name}) {
		$name = $ren;
	}
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
