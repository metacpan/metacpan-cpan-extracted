#!/usr/bin/env perl

use warnings;
use strict;

my $PROG = 'repoadd.pl';

package PkgFile;

sub fromPath { my $self = bless {}, shift; $self->{'path'} = shift; $self; }

sub info
{
	my($self) = @_;
	return $self->{'info'} if($self->{'info'});

	if(-e '.PKGINFO'){
		print STDERR "PROG: .PKGINFO already exists in current dir, please delete it.\n";
		exit 1;
	}

	my $path = $self->{'path'};
	system "cat $path | xz -dc | bsdtar -xf - .PKGINFO";
	if(@? || !-f '.PKGINFO'){
		print STDERR "$PROG: failed to extract .PKGINFO from $path\n";
		exit 1;
	}

	open my $if, '<.PKGINFO' or die "open: $!";
	my %pi;

	for my $ln (<$if>){
		next if($ln =~ /^\#/);
		chomp $ln;
		my($name, $val) = split /\s*=\s*/, $ln, 2;
		$name =~ s/^pkg//;
		push @{$pi{$name}}, $val;
	}

	close $if;
	unlink '.PKGINFO';
	$pi{'version'} = delete $pi{'ver'};
	return $self->{'info'} = \%pi;
}

sub fileName
{
	my($self) = @_;
	my $fn = $self->{'path'};
	$fn =~ s{.*/}{};
	return $fn;
}

package DBDir;

our @DescFields = qw{filename name base version desc groups
	csize isize url license arch builddate packager replaces};
our @DepFields = qw/depends provides conflicts optdepends/;

sub fromPath
{
	my $self = bless {}, shift;
	$self->{'dir'} = shift;
	$self;
}

sub writeFile
{
	my($self, $path, $data) = @_;

	open my $of, '>', $path or die "open: $!";
	while(my($k, $v) = each %$data){
		my $str = join "\n", @$v;
		my $uck = uc $k;
		print $of "%$uck%\n$str\n\n";
	}
	close $of or die "close: $!";
	$self;
}

sub addEntry
{
	my($self, $pkg) = @_;

	my $pi = $pkg->info;
	my $name = join q{-}, map { $_->[0] } @{$pi}{qw/name version/};

	my $dir = "$self->{'dir'}/$name";
	if(-d $dir){
		system 'rm' => '-r', "$dir";
		if($?){
			print STDERR "$PROG: failed to unlink dir: $dir\n";
			exit 1;
		}
	}
	mkdir $dir or die "mkdir: $!";

	my %deps;
	for my $dkey (@DepFields){
		$deps{$dkey} = delete $pi->{$dkey} if($pi->{$dkey});
	}
	$self->writeFile("$dir/depends", \%deps);

	$pi->{'filename'} = [ $pkg->fileName ];
	for my $fld (@DescFields){
		$pi->{$fld} = [] unless($pi->{$fld});
	}
	$self->writeFile("$dir/desc", $pi);
}

package main;

sub usage
{
	print STDERR "usage: $PROG [repo dir path] [package path]\n";
	exit 2;
}

sub main
{
	usage() if(@_ != 2);
	my($dbname, $pkgpath) = @_;

	my $dbdir = "$dbname/contents";
	unless(-d $dbdir){
		print STDERR "$PROG: dir named $dbname must exist in current directory\n";
		exit 1;
	}
	unless(-f $pkgpath){
		print STDERR "$PROG: $pkgpath is not a valid path\n";
		exit 1;
	}
	my $db = DBDir->fromPath($dbdir);
	my $pkg = PkgFile->fromPath($pkgpath);
	$db->addEntry($pkg);

	my $dest = "$dbname/" . $pkg->fileName;
	rename $pkgpath, $dest or die "rename: $!";

	return 0;
}

exit main(@ARGV);
