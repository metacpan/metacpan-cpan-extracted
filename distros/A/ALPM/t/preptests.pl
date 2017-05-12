#!/usr/bin/env perl
use warnings;
use strict;

use Cwd;
use English qw(-no_match_vars);
use File::Find;
use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Spec::Functions qw(rel2abs catfile);
use File::Basename qw(dirname);

my $PROG = 'preptests';
my $REPODIR = 'repos';

## Variables inside the test.conf need absolute paths, assigned later.
my ($REPOSHARE, $TESTROOT);
my $TESTCONF = 'test.conf';

sub createconf
{
	my($path, $root, $repos) = @_;
	open my $of, '>', $path
		or die "failed to open t/test.conf file: $!";
	print $of <<"END_CONF";
[options]
RootDir = $root
DBPath = $root/db
CacheDir = $root/cache
LogFile = $root/test.log
#GPGDir      = $root/gnupg/
HoldPkg     = pacman glibc
SyncFirst   = pacman
#XferCommand = /usr/bin/curl -C - -f %u > %o
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
CleanMethod = KeepInstalled
Architecture = auto

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
#UseDelta
#TotalDownload
CheckSpace
#VerbosePkgLists

# PGP signature checking
SigLevel = Optional

END_CONF

	while(my($repo, $path) = each %$repos){
		print $of <<"END_CONF"
[$repo]
SigLevel = Optional TrustAll
Server = file://$path

END_CONF
	}

	close $of;
}

sub buildpkgs
{
	chdir 'repos' or die "chdir: $!";
	my @lines = `perl package.pl`;
	chdir '..' or die "chdir: $!";

	if(@?){
		printf STDERR "$PROG: package.pl script failed: code %d\n", $? >> 8;
		exit 1;
	}

	my %repos;
	for (@lines){
		chomp;
		my($r, @rest) = split /\t/;
		push @{$repos{$r}}, join "\t", @rest;
	}

	return \%repos;
}

sub remkdir
{
	my($dir) = @_;
	die "WTF?" if($dir eq '/');
	remove_tree($dir);
	mkdir($dir);
	return;
}

sub mkroot
{
	remkdir($TESTROOT);
	my @dirs = glob("$TESTROOT/{gnupg,cache,{db/{local,cache}}}");
	make_path(@dirs, { mode => 0755 });
}

sub corruptpkg
{
	my $fqp = "$REPOSHARE/simpletest/corruptme-1.0-1-any.pkg.tar.xz";
	unlink $fqp or die "unlink: $!";

	open my $fh, '>', $fqp or die "open: $!";
	print $fh "HAHA PWNED!\n";
	close $fh or die "close: $!";

	return;
}

sub buildrepos
{
	my($sharedir) = @_;
	my $repos = buildpkgs();
	my $wd = getcwd();
	chdir($REPODIR) or die "chdir: $!";

	my %paths;
	for my $r (sort keys %$repos){
		my $rd = "$sharedir/$r";
		make_path("$rd/contents");

		for my $pkg (@{$repos->{$r}}){
			system 'perl' => 'repoadd.pl', $rd, $pkg;
			if($?){
				print STDERR "$PROG: repoadd.pl failed\n";
				exit 1;
			}
		}
		system 'perl' => 'repofin.pl', $rd;
		if($?){
			print STDERR "$PROG: repofin.pl failed\n";
			exit 1;
		}

		$paths{$r} = $rd;
	}

	chdir $wd or die "chdir: $!";
	return \%paths;
}

sub main
{
	chdir(dirname($0)) or die "chdir: $!";

	$REPOSHARE = rel2abs('repos/share');
	$TESTROOT = rel2abs('root');
	unless(-d $REPOSHARE){
		my $repos = buildrepos($REPOSHARE);
		createconf($TESTCONF, $TESTROOT, $repos);
	}

	#corruptpkg();

	# Allows me to tweak the test.conf file and not have it overwritten...
	mkroot();

	return 0;
}

exit main(@ARGV);
