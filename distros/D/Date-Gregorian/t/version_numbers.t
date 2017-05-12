# Copyright (c) 2006-2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# check if version numbers match

use strict;
use Date::Gregorian;

sub test {
    my ($n, $ok) = @_;
    print !$ok && 'not ', "ok $n\n";
}

sub skip {
    my ($from, $to, $reason) = @_;
    print map "ok $_ # SKIP $reason\n", $from..$to;
}

sub skip_all {
    my ($reason) = @_;
    print "1..0 # SKIP $reason\n";
    exit 0;
}

sub use_or_bail {
    my ($module) = @_;
    eval "use $module";
    skip_all "$module not available" if $@;
}

$| = 1;
undef $/;

my $README = 'README';
my $META_YML = 'META.yml';
my $distname = 'Date-Gregorian';
my $modname = 'Date::Gregorian';

use_or_bail 'File::Spec';
use_or_bail 'File::Basename';
use_or_bail 'FindBin';

my $distroot = '.' eq $FindBin::Bin? '..': dirname($FindBin::Bin);

print "1..9\n";

my $mod_version = '' . $Date::Gregorian::VERSION;

$mod_version = 'undef' if !defined $mod_version;
print "# module version is $mod_version\n";
test 1, $mod_version =~ /^\d+\.\d+\z/;

if ($distroot =~ /\b\Q$distname\E-(\d+\.\d+)(?:-\w+)?\z/) {
    test 2, $mod_version eq $1;
}
else {
    skip 2, 2, "not running in numbered distro dir";
}

my $readme_file = File::Spec->catfile($distroot, $README);
if (open FILE, "< $readme_file") {
    my $readme = <FILE>;
    close FILE;
    my $found =
	$readme =~ /^This is Version\s+(\d+\.\d+)\s+of\s+(\S+)\.$/mi;
    test 3, $found;
    if ($found) {
	test 4, $2 eq $modname || $2 eq $distname;
	test 5, $1 eq $mod_version;
    }
    else {
	skip 4, 5, "unknown $README version";
    }
}
else {
    skip 3, 5, "cannot open $README file";
}

my $metayml_file = File::Spec->catfile($distroot, $META_YML);
if (open FILE, "< $metayml_file") {
    my $metayml = <FILE>;
    close FILE;
    my $found_dist = $metayml =~ /^name:\s+(\S+)$/mi;
    test 6, $found_dist;
    if ($found_dist) {
	test 7, $1 eq $distname;
    }
    else {
	skip 7, 7, "unknown $META_YML dist name";
    }
    my $found_vers = $metayml =~ /^version:\s+(\S+)$/mi;
    test 8, $found_vers;
    if ($found_dist) {
	test 9, $1 eq $mod_version;
    }
    else {
	skip 9, 9, "unknown $META_YML dist name";
    }
}
else {
    skip 6, 9, "cannot open $META_YML file";
}

__END__
