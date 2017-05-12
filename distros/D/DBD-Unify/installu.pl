#!/pro/bin/perl -w

use strict;

use Config;
use Cwd;
use File::Find;
use File::Copy;

exists $ENV{UNIFY} && -d $ENV{UNIFY} or die "Not in (valid) UNIFY env";

my $version = $Config{version};
my $arch    = $Config{archname};

my %tar;
my $src = getcwd;
foreach my $loc (qw( arch lib man3 )) {
    chdir "$src/blib/$loc" or die "No $loc";
    find (sub {
	m/^\.+$/ and return;
	(my $f = $File::Find::name) =~ s:^./::;
	push @{$tar{$loc}}, $f;
	}, ".");
    }

-d "$ENV{UNIFY}/perl"                or
    mkdir "$ENV{UNIFY}/perl", 0775;
-d "$ENV{UNIFY}/perl/$version"       or
    mkdir "$ENV{UNIFY}/perl/$version", 0775;
-d "$ENV{UNIFY}/perl/$version/$arch" or
    mkdir "$ENV{UNIFY}/perl/$version/$arch", 0775;

my $dst = "$ENV{UNIFY}/perl/$version";
foreach my $f (sort @{$tar{lib}}) {
    my $s = "$src/blib/lib/$f";
    if (-d $s) {
	print STDERR "mkdir $dst/$f ...\n";
	mkdir "$dst/$f", 0775;
	next;
	}
    print STDERR "lib   cp lib/$f\n";
    copy ("$src/blib/lib/$f", "$dst/$f");
    $f =~ m/\.(sl|al|pm|bs)$/ and chmod 0755, "$dst/$f";
    }
$dst = "$ENV{UNIFY}/perl/$version/$arch";
foreach my $f (sort @{$tar{arch}}) {
    my $s = "$src/blib/arch/$f";
    if (-d $s) {
	print STDERR "mkdir $dst/$f ...\n";
	mkdir "$dst/$f", 0775;
	next;
	}
    print STDERR "arch  cp arch/$f\n";
    copy ("$src/blib/arch/$f", "$dst/$f");
    $f =~ m/\.(sl|so|al|pm|bs)$/ and chmod 0755, "$dst/$f";
    }
