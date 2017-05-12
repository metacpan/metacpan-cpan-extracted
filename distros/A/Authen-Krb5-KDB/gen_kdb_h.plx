#!perl

# $Id: gen_kdb_h.plx,v 1.8 2002/10/09 20:38:25 steiner Exp $

use ExtUtils::MakeMaker;
use Config;
use strict;

# Code based on the script Errno_pm.PL in the Errno-1.09 module.

use vars qw($VERSION $Usage %Comments $Krb5Version);

$VERSION = do{my@r=q$Revision: 1.8 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

$Usage = "Usage: $0 <krb5_src_path>\n";

my %defines = ();
my @defines = ();
my $PM_File = "KDB_H.pm";
my $dist_PM_File = "KDB_H.pm.dist";
my $C_File = "kdb_h.c";
my $cppdefine = '-DSECURID';	# want this value regardless

if (! -f $dist_PM_File) {	# save distributed copy, but only first time
    rename($PM_File, $dist_PM_File) or
	warn "Can't rename $PM_File to $dist_PM_File: $!";
}
unlink $PM_File if -f $PM_File;
open OUT, ">$PM_File" or die "Cannot open $PM_File: $!";
select OUT;

my $srcspath;
$srcspath = shift;
if (not defined($srcspath)) { die "Must give path to krb5 srcs\n$Usage"; }

my $patchlevel_h = "$srcspath/patchlevel.h";
my $kdb_h = "$srcspath/include/krb5/kdb.h";

get_version($patchlevel_h);
process_file($kdb_h);
write_pm($kdb_h);
unlink $C_File if -f $C_File;


sub get_version {
    my($file) = @_;
    my ($major, $minor, $patch) = ('?', '?', '?');

    local *VFH;
    if (($^O eq 'VMS') && ($Config{vms_cc_type} ne 'gnuc')) {
	open(VFH," LIBRARY/EXTRACT=ERRNO/OUTPUT=SYS\$OUTPUT $file |") or
            die "Can't open Version file '$file': $!\n";
    } else {
	open(VFH,"< $file") or die "Can't open Version file '$file': $!\n";
    }
    while (<VFH>) {
	if (/^\s*#\s*define\s+KRB5_MAJOR_RELEASE\s+(\d+)/) {
	    $major = $1;
	} elsif (/^\s*#\s*define\s+KRB5_MINOR_RELEASE\s+(\d+)/) {
	    $minor = $1;
	} elsif (/^\s*#\s*define\s+KRB5_PATCHLEVEL\s+(\d+)/) {
	    $patch = $1;
	}
    }
    close VFH;
    $Krb5Version = "$major.$minor.$patch";
}

sub process_file {
    my($file) = @_;
    my $comment;

    return unless defined $file;

    local *FH;
    if (($^O eq 'VMS') && ($Config{vms_cc_type} ne 'gnuc')) {
	unless(open(FH," LIBRARY/EXTRACT=ERRNO/OUTPUT=SYS\$OUTPUT $file |")) {
            warn "Cannot open '$file'";
            return;
	}     
    } else {
	unless(open(FH,"< $file")) {
            warn "Cannot open '$file'";
            return;
	}
    }
    while(<FH>) {
	if (m|^\s*/\*\s*(.*)\s*\*/\s*$|) {
	    $comment = $1;
	    if ($comment =~ /^XXX/) { $comment = ""; }
	    else {
		$comment = join('', map { ucfirst } split(' ', $comment));
		$Comments{$comment} = [];
	    }
	}
	if (/^\s*#\s*define\s+(KRB5_(?:KDB|TL)_\w+)\s+/) {
	    my $name = $1;
	    push @defines, $name;
	    if ($name =~ /_TL_/) {
		push @{$Comments{'TLTypes'}}, $name;
	    } else {
		push @{$Comments{$comment}}, $name;
	    }
	}

	$comment = ""  if /^\s*$/;  # reset
   }
   close(FH);
}

sub write_pm {
    my($file) = @_;
    my(@valid_tags);

    # create the CPP input

    open(CPPI,"> $C_File") or
	die "Cannot open $C_File";

    print CPPI "#include <$file>\n";

    foreach my $define (@defines) {
	print CPPI '"',$define,'" [[',$define,']]',"\n";
    }

    close(CPPI);

    # invoke CPP and read the output

    if ($^O eq 'VMS') {
	my $cpp = "$Config{cppstdin} $Config{cppflags} $cppdefine $Config{cppminus}";
	$cpp =~ s/sys\$input//i;
	open(CPPO,"$cpp  $C_File |") or
          die "Cannot exec $Config{cppstdin}";
    } elsif($^O eq 'next') {
	# NeXT will do syntax checking unless it is reading from stdin
        my $cpp = "$Config{cppstdin} $Config{cppflags} $cppdefine $Config{cppminus}";
        open(CPPO,"$cpp < $C_File |")
	    or die "Cannot exec $cpp";
    } else {
	open(CPPO,"$Config{cpprun} $Config{cppflags} $cppdefine $C_File |") or
	    die "Cannot exec $Config{cpprun}";
    }

    while(<CPPO>) {
	my($name,$expr);
	next unless ($name, $expr) = /"(.*?)"\s*\[\s*\[\s*(.*?)\s*\]\s*\]/;
	next if $name eq $expr;
#	$defines{$name} = eval $expr;
	$defines{$name} = $expr;
    }
    close(CPPO);

    # Write KDB_H.pm

    print <<"EOH";
#
# This file is auto-generated. ***ANY*** changes here will be lost
#
# Kerberos Version: $Krb5Version
# File: $file

package Authen::Krb5::KDB_H;
use vars qw(\@EXPORT_OK \%EXPORT_TAGS \@ISA \$VERSION);
use Exporter ();
use strict;

\$VERSION = "$VERSION";
\@ISA = qw(Exporter);

EOH
   
    my $j = "\@EXPORT_OK = qw( " . join(" ",@defines) . " );\n";
    $j =~ s/(.{48,70})\s/$1\n\t/g;
    print $j,"\n";

    print "\%EXPORT_TAGS = (\n";
    print "  ALL => [ \@EXPORT_OK ],\n\n";
    foreach my $tag (keys %Comments) {
	next if (not $tag);
	next if (not scalar @{$Comments{$tag}});
	my $k = "  $tag => [qw( ";
	$k .= join(" ", @{$Comments{$tag}});
	$k =~ s/(.{48,70})\s/$1\n\t/g;
	print $k," )],\n\n";
	push @valid_tags, $tag;
    }
    print ");\n\n";

    my $len = 0;
    map { $len = length if length > $len } @defines;

    foreach my $define (@defines) {
	printf "sub %s () %s { %s }\n", $define,
	   " " x ($len - length($define)), $defines{$define};
    }

    print <<'EPOD';

1;
__END__

=head1 NAME

Authen::Krb5::KDB_H - Kerberos V5 Database Constants

=head1 SYNOPSIS

    use Authen::Krb5::KDB_H;
    use Authen::Krb5::KDB_H qw(KRB5_KDB_REQUIRES_PRE_AUTH);
    use Authen::Krb5::KDB_H qw(:Attributes);
    use Authen::Krb5::KDB_H qw(:ALL);

    if ($p->attributes & KRB5_KDB_REQUIRES_PRE_AUTH) {
	print $p->name, ": Requires Pre Auth\n";
    }


=head1 DESCRIPTION

This module allows access to the KRB5_* constants in Kerberos source
file F<include/krb5/kdb.h>.  Nothing is exported by default so you
either need to export the constants you need or use on the following
Export Tags:

EPOD

    foreach my $tag (sort @valid_tags) {
	print "=over 4\n\n";
	print "=item :$tag\n\n";
	my $k = join("  ", @{$Comments{$tag}});
	$k =~ s/(.{48,70})\s\s/$1\n/g; # note we use two spaces here
	print "$k\n\n";
	print "=back\n\n";
    }

    print "=over 4\n\n";
    print "=item :ALL\n\n";
    my $k = join("  ", @defines);
    $k =~ s/(.{48,70})\s\s/$1\n/g; # note we use two spaces here
    print "$k\n\n";
    print "=back\n\n";

    print <<'EPOD';

=head1 AUTHOR

Dave Steiner, E<lt>steiner@bakerst.rutgers.eduE<gt>

=head1 COPYRIGHT

Copyright (c) 2002 David K. Steiner. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), kerberos(1), Authen::Krb5::KDB.

=cut

EPOD

}
