# -*- mode: perl; coding: utf-8; tab-width: 4; -*-

package Cv::Config;

use 5.008008;
use strict;
use warnings;
use Carp;
use Cwd qw(abs_path);
use File::Basename;
use ExtUtils::PkgConfig;
use version;

our $VERSION = '0.29';

our %opencv;
our %MM;
our %C;

our $verbose = 0;

sub new {
	bless {};
}

sub cvdir {
	my $self = shift;
	unless (defined $self->{cvdir}) {
		(my $me = __PACKAGE__ . '.pm') =~ s|::|/|g;
		$self->{cvdir} = abs_path(dirname($INC{$me}));
	}
	$self->{cvdir};
}


sub typemaps {
	my $self = shift;
	my $cvdir = $self->cvdir;
	unless (defined $self->{TYPEMAPS}) {
		$self->{TYPEMAPS} = [ "$cvdir/typemap" ];
	}
	$self->{TYPEMAPS};
}


sub cc {
	my $self = shift;
	unless (defined $self->{CC}) {
		$self->{CC} = $ENV{CXX} || $ENV{CC} || 'c++';
	}
	$self->{CC};
}


sub libs {
	my $self = shift;
	unless (defined $self->{LIBS}) {
		my @libs = split(/\s+/, $opencv{libs});
		if ($libs[0] =~ m{(/.*)/libopencv}) {
			my $dir = $1;
			s{$dir/lib}{-l} for @libs;
			unshift(@libs, "-L$dir");
		}
		s{(-\d+\.\d+)?(\.(so|dll))?$}{} for @libs;
		$self->{LIBS} = [ join(' ', @libs) ];
	}
	$self->{LIBS};
}


sub dynamic_lib {
	my $self = shift;
	my $cc = $self->cc;
	unless (defined $self->{dynamic_lib}) {
		if (open(CC, "$cc -v 2>&1 |")) {
			my %cf;
			while (<CC>) {
				if (/^Configured with:\s*/) {
					while (/(-[-\w]+)=('[^']*'|[^\s]*)/g) {
						$cf{$1} = $2;
					}
				}
			}
			$self->{dynamic_lib} = { };
			if (my $rpath = $cf{'--libdir'} || $cf{'--libexecdir'}) {
				$self->{dynamic_lib}{OTHERLDFLAGS} = "-Wl,-rpath=$rpath",
			}
			close CC;
		}
	}
	$self->{dynamic_lib};
}


sub ccflags {
	my $self = shift;
	my $cvdir = $self->cvdir;
	unless (defined $self->{CCFLAGS}) {
		my @inc = ("-I$cvdir"); my %seen = ();
		my @ccflags = ();
		foreach (split(/\s+/, $opencv{cflags})) {
			if (/^-I/) {
				s/(-I.*)\bopencv/$1/;
				next if $seen{$_}++;
				push(@inc, $_);
			} else {
				push(@ccflags, $_);
			}
		}
		$self->{CCFLAGS} = join(' ', @inc, @ccflags);
	}
	$self->{CCFLAGS};
}


sub hasqt {
	my $self = shift;
	unless (defined $self->{hasqt}) {
		my $c = "/tmp/cv$$.c";
		warn "Compiling $c to check you have qt.\n" if $verbose;
		my $CC = $self->cc;
		my $CCFLAGS = $self->ccflags;
		my $LIBS = join(' ', @{$self->libs});
		if (my $dynamic_lib = $self->dynamic_lib) {
			if ($dynamic_lib->{OTHERLDFLAGS}) {
				$LIBS .= " " . $dynamic_lib->{OTHERLDFLAGS};
			}
		}
		if (open C, ">$c") {
			print C <<"----";
#include <stdio.h>
#include <opencv/cv.h>
#include <opencv/highgui.h>
main()
{
	CvFont font = cvFontQt("Times");
	exit(0);
}
----
	;
			close C;
			warn "$CC $CCFLAGS -o a.exe $c $LIBS\n" if $verbose;
			chop(my $v = `$CC $CCFLAGS -o a.exe $c $LIBS 2>/dev/null && ./a.exe`);
			$self->{hasqt} = $? == 0;
			unlink($c, 'a.exe');
		} else {
			die "$0: can't open $c.\n";
		}
	}
	$self->{hasqt};
}


sub _version {
	my $self = shift;
	unless (defined $self->{version}) {
		$self->{version} = version->parse($opencv{modversion});
	}
	$self->{version};
}


sub version {
	my $self = shift;
	if ($self->_version->normal =~ /v?(\d+)\.(\d+)\.(\d+)/) {
		return sprintf("%d.%03d%03d", $1, $2, $3);
	}
	undef;
}


BEGIN {
	%opencv = ExtUtils::PkgConfig->find('opencv');
	my $cf = __PACKAGE__->new;

	# ExtUtils::MakeMaker
	%MM = (
		CC       => $cf->cc,
		LD       => $cf->cc,
		CCFLAGS  => $cf->ccflags,
		LIBS     => $cf->libs,
		# MYEXTLIB => $cf->myextlib,
		TYPEMAPS => $cf->typemaps,
		);

	# Inline::C
	%C = (
		%MM,
		AUTO_INCLUDE => join("\n", (
								 '#undef do_open',
								 '#undef do_close',
								 # '#define __Inline_C',
								 # '#include "Cv.inc"',
								 '',
							 )),
		);
}

1;
