#!/usr/bin/env perl

use File::Basename qw(basename dirname);
use File::Find qw(find);
use File::Copy qw(copy);
use Cwd qw(getcwd);
use File::stat;

use warnings;
use strict;

our $PROG='t/package.pl';

sub sumfiles
{
	my($pd) = @_;
	my $sum;
	find(sub { $sum += -s $_ if(-f $_ && !/.PKGINFO/); }, $pd);
	return $sum;
}

sub readpi
{
	my($ipath) = @_;
	unless(-f $ipath && -r $ipath){
		print STDERR "$PROG: $ipath is missing.\n";
		exit 1;
	}

	my %pinfo;
	open my $if, '<', $ipath or die "open: $!";
	while(<$if>){
		my ($name, $val) = split / = /;
		my @vals = split /\s+/, $val;
		$pinfo{$name} = \@vals;
	}
	close $if or die "close: $!";
	return \%pinfo;
}

sub writepi
{
	my($pinfo, $ipath) = @_;

	open my $of, '>', $ipath or die "open: $!";
	while(my($k, $v) = each %$pinfo){
		print $of "$k = @$v\n";
	}
	close $of or die "close: $!";
	return;
}

sub updatepi
{
	my($pi, $pd) = @_;
	$pi->{'builddate'} = [ time ];
	$pi->{'size'} = [ sumfiles($pd) ];
	$pi->{'packager'} = [ 'ALPM Module' ];
	return;
}

sub remkdir
{
	my($d) = @_;
	if(-d $d){
		system 'rm' => ('-r', $d);
		if($?){
			printf STDERR "$PROG: rm -r $d failed: error code %d\n", $? >> 8;
			exit 1;
		}
	}
	unless(mkdir $d){
		print STDERR "$PROG: mkdir $d failed: $!\n";
		exit 1;
	}
	return;
}

sub mktmpdir
{
	my($base) = @_;
	remkdir("$base/tmp");
	return "$base/tmp";
}

sub pkgfname
{
	my($pi) = @_;
	return sprintf '%s-%s-%s.pkg.tar.xz',
		map { $_->[0] } @{$pi}{qw/pkgname pkgver arch/};
}

sub buildpkg
{
	my($pi, $pd, $td) = @_;

	my $parentd = dirname($td);
	remkdir($td);
	system 'cp' => ('-R', $pd, $parentd);
	if($?){
		print STDERR "$PROG: failed to cp $pd to $parentd\n";
		exit 1;
	}

	unlink("$td/.PKGINFO") or die "unlink: $!";
	updatepi($pi, $td);
	writepi($pi, "$td/.PKGINFO");

	my $fname = pkgfname($pi);
	my $oldwd = getcwd();
	chdir $td or die "chdir: $!";
	system qq{bsdtar -cf - .PKGINFO * | xz -z > ../$fname};
	if($?){
		printf STDERR "$PROG: xz returned %d\n", $? >> 8;
		exit 1;
	}
	chdir $oldwd or die "chdir: $!";

	return "$parentd/$fname";
}

sub dirsin
{
	my($p) = @_;
	opendir my $dh, $p or die "opendir $p: $!";
	my @dirs = grep { !/^[.]/ && -d "$p/$_" } readdir $dh;
	closedir $dh;
	return @dirs;
}

sub readrepos
{
	my($based) = @_;
	my %rpkgs;
	for my $r (dirsin($based)){
		next if($r eq 'tmp');
		push @{$rpkgs{$r}}, dirsin("$based/$r");
	}
	return \%rpkgs;
}

sub findbuilt
{
	my($pi, $pd, $td) = @_;

	unless(-f "$pd/.PKGINFO"){
		print STDERR "$PROG: $pd/.PKGINFO is missing\n";
		exit 1;
	}

	return undef unless(-d $td);
	my $fname = pkgfname($pi);
	return undef unless(-f "$td/$fname");

	my($itime, $ptime) = map { my $s = stat $_; $s->mtime }
		("$pd/.PKGINFO", "$td/$fname");
	return undef if($itime > $ptime);
	return "$td/$fname";
}

my $wd = getcwd();
my $bd = 'build';
my $td = mktmpdir($bd);
my $repos = readrepos($bd);
my @pkgfiles;

for my $repo (sort keys %$repos){
	my $rd = "$bd/$repo";
	for my $p (sort @{$repos->{$repo}}){
		my $srcd = "$rd/$p";
		my $destd = "$td/$p";
		my $pi = readpi("$srcd/.PKGINFO");
		my $pkgp = findbuilt($pi, $srcd, $rd);
		unless($pkgp){
			my $tmpp = buildpkg($pi, $srcd, $destd);
			$pkgp = "$rd/" . basename($tmpp);
			unless(copy($tmpp, $pkgp)){
				printf STDERR "$PROG: copy $tmpp to $pkgp failed: $!";
				exit 1;
			}
		}
		print "$repo\t$wd/$pkgp\n";
	}
}
