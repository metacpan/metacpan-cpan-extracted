#!/usr/bin/env perl
# ABSTRACT: Script to test a ZMQ::* package on each system

use strict;
use warnings;

use Env qw(@PATH $PERL_CPANM_OPT $ARCHFLAGS);
use Alien::ZMQ::latest;

sub cpanm {
	my (@args) = @_;

	my @default = qw(--test-only --build-args 'OTHERLDFLAGS=' --verbose);
	my $exit = system(qw(cpanm), @default, @args);

	die "cpanm @default @args failed" if $exit;
}

sub install_windows {
	my ($package) = @_;
	# set PATH to libzmq.dll before installing ZMQ::LibZMQ3
	push @PATH, Alien::ZMQ::latest->bin_dir;
	delete $ENV{PERL_CPANM_OPT};
	cpanm($package);
}
sub install_macos {
	my ($package) = @_;
	$ARCHFLAGS = '-arch x86_64';
	cpanm($package);
}

sub install_linux {
	my ($package) = @_;
	cpanm($package);
}

sub main {
	my ($package) = @ARGV;
	if( $^O eq 'MSWin32' ) {
		install_windows($package);
	} elsif( $^O eq 'darwin' ) {
		install_macos($package);
	} elsif( $^O eq 'linux' ) {
		install_linux($package);
	} else {
		die "unknown OS";
	}
}

main;
