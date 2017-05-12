#!/usr/bin/perl -w

use strict;

package misc::MakeMakerMod;
our $VERSION = '0.001';

sub add_steps {
	my %args = @_;
	my $file = $args{file} || "Makefile";
	my $step = $args{step} || "install";
	my $what = $args{what} || die "must provide a what argument";

	#read the Makefile
	open(MF, "<$file") || die "can't open Makefile for reading";
	my @lines = <MF>;
	close(MF);

	#find the step we're interested in
	my ($c, $ln) = (0,0);
	map { $c++; $ln = $c if(grep(/^$step\s+\:/, $_)); } @lines;

	#write the Makefile back out with extra commands in the install step
	open(MF, ">$file") || die "can't open Makefile for writing";
	map { print MF $_ } @lines[0..$ln-1];
	print MF "\n\t################################\n";
	print MF "\t### added by MakeMakerMod.pm ###\n";
	print MF "\t################################\n";
	map { my $l = "\t  $_"; chomp($l); print MF "$l\n" } 
		split("\n", $what);
	print MF "\t#################################\n";
	print MF "\t### /added by MakeMakerMod.pm ###\n";
	print MF "\t#################################\n\n";
	map { print MF $_ } @lines[$ln..$#lines];
	close(MF);
}

1;
__END__

=begin text

wtf

=end text

=head1 NAME

MakeMakerMod - easily modify MakeMaker Makefiles

=head1 SYNOPSIS

It's quite difficult to do something as simple as
adding an install step to be run at install time (if
it is even possible at all) with ExtUtils::MakeMaker.
This module hackishly fixes that.

Example usage would look something like this:

  WriteMakefile(%args);
  MakeMakerMod::add_steps(
    step => "install",
    what => "perl misc/install-extras.pl"
  );

=head1 DESCRIPTION

  A horrible hack that can be horribly useful.

=head1 AUTHOR
   
  Brian Szymanski <scache@allafrica.com>

=cut

