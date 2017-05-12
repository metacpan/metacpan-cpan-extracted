#!/usr/bin/perl
#
# @(#)$Id: esqlld.pl,v 2015.1 2015/08/21 22:55:19 jleffler Exp $ 
#
# Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
#
# Surrogate Linker for Informix ESQL/C versions 4.10.UC1 upwards
# -- Used to create shared libraries.
#
# Copyright 1996-99 Jonathan Leffler
# Copyright 2000    Informix Software Inc
# Copyright 2002-03 IBM
# Copyright 2005    Jonathan Leffler
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

# Ensure we use distributed version of DBD::Informix::Configure,
# not pre-installed out-of-date version of it.
BEGIN
{
unshift @INC, "lib";
use constant debug => ($ENV{DBD_INFORMIX_DEBUG_ESQLLD} ? 1 : 0);
}

use strict;
use warnings;
use DBD::Informix::Configure;	# &map_informix_lib_names()

my $map = ($ENV{DBD_INFORMIX_RELOCATABLE_INFORMIXDIR}) ? 0 : 1;
my @ARGS = $map ? &map_informix_lib_names(@ARGV) : @ARGV;

# JL 1997-04-08: Add -lc to command line (reason why no longer known)
push @ARGS, "-lc";

# Remove C preprocessor options from linker command line
@ARGS = grep { !m/^-[DIU]/o } @ARGS;

# Roderick Schertler <roderick@argon.org> 1999-07-27:
# I got "SEVERE LIBC ERROR: CALL TO __mutex_unlock FAILED" when
# linked with -lthread under dgux 4.11.mu05 on m88k.  According
# to DG (ticket l574314) that can happen if you use a shared
# library which uses -lthread with one which doesn't.  I don't
# know why this never came up before.
@ARGS = grep { !m/^-lthread/o } @ARGS
	if ($^O eq 'dgux');

# Remove -g option from linker command line when requested.
# Problem found on SCO 3.2v5.0.2 by Brad Huan-Ming Kao
# <proton@iiidns.iii.org.tw>
@ARGS = grep { !m/^-g$/o } @ARGS
	if ($ENV{DBD_INFORMIX_ESQLLD_NO_G_OPTION});

# Generalization of DBD_INFORMIX_ESQLLD_NO_G_OPTION...
if ($ENV{DBD_INFORMIX_ESQLLD_REMOVE_OPTIONS_REGEX})
{
	my($env) = $ENV{DBD_INFORMIX_ESQLLD_REMOVE_OPTIONS_REGEX};
	print STDERR "# DBD_INFORMIX_ESQLLD_REMOVE_OPTIONS_REGEX set.\n";
	print STDERR "# Removing options that match regex m%$env%\n";
	print STDERR "# Before: @ARGS\n" if debug;
	@ARGS = grep { !m%$env%o } @ARGS;
	print STDERR "# After: @ARGS\n" if debug;
}

# How to deal with mapping -xarch=sparcv9 to -m64?  Need to provide a
# mechanism to do search/replace.  How to specify? qr// only handles
# single regexes, not both parts of s///.  So, we can do it with two
# environment variables (one to search, one to replace), or with one
# that contains a complete 's///' pattern.  If there are many mappings
# to do (eg -KPIC => -fPIC as well), this may be inadequate.
# Comment: It is surprisingly hard to do this right!
# ******** There has to be a better way using map and a block - surely?
# Note that this code is vulnerable to spaces in arguments.  We can
# check for these when they prove to be a problem.
if ($ENV{DBD_INFORMIX_ESQLLD_REPLACE_OPTIONS_REGEX})
{
	my($env) = $ENV{DBD_INFORMIX_ESQLLD_REPLACE_OPTIONS_REGEX};
	print STDERR "# DBD_INFORMIX_ESQLLD_REPLACE_OPTIONS_REGEX set.\n";
	die "Malformed regex ($env) not similar enough to s/a/b/\n"
		unless ($env =~ m/^s(.).*\1.*\1$/);
	print STDERR "# Replacing options using regex $env\n";
	print STDERR "# Before: @ARGS\n" if debug;
	my $sub = qq%sub { my(\$s) = "\@_"; \$s =~ ${env}go; return \$s; }%;
	print STDERR "# Mapper: $sub\n" if debug;
	my $mapper = eval $sub or die "Unable to compile $sub";
	@ARGS = split / +/, &$mapper(@ARGS);
	print STDERR "# After: @ARGS\n" if debug;
}

# A variant of the code for DBD_INFORMIX_ESQLLD_REPLACE_OPTIONS_REGEX.
# How to deal with removing "-z ignore" - two adjacent options?
# The "-z ignore" option pair, along with "-z lazyload" and "-z
# combreloc", sometimes causes trouble on some Solaris platforms with
# GCC.  To remove these - set the env var (its name is deliberately very
# long) to: "-z\s*(ignore|combreloc|lazyload)\b".
# The easiest way is to flatten the arguments into a string, do a global
# delete, and a split (in the calling code?).
# Note that this code is vulnerable to spaces in arguments.  We can
# check for these when they prove to be a problem.
# Note that despite the function name, it is perfectly capable of
# removing singletons, triplets, quadruplets, quintuplets, sextuplets,
# septuplets, octuplets, and so on.
sub remove_option_pairs
{
	my(@ARGS) = @_;
	my($flat) = "@ARGS";
	if ($ENV{DBD_INFORMIX_ESQLLD_REMOVE_OPTION_PAIRS})
	{
		my($env) = $ENV{DBD_INFORMIX_ESQLLD_REMOVE_OPTION_PAIRS};
		print STDERR "# DBD_INFORMIX_ESQLLD_REMOVE_OPTION_PAIRS set.\n";
		print STDERR "# Removing option pairs that match regex s%$env%%g\n";
		print STDERR "# Before: $flat\n";
		$flat =~ s%$env%%g;
		print STDERR "# After: $flat\n";
	}
	return "$flat";
}

@ARGS = split / +/, &remove_option_pairs(@ARGS)
			if ($ENV{DBD_INFORMIX_ESQLLD_REMOVE_OPTION_PAIRS});

# Sort out the real compiler.
# Note that if $ENV{ESQLLD} contains, for example, 'cc -G', then we
# need to split this into two words for the exec to work correctly.
my $cmd = $ENV{ESQLLD};
   $cmd = 'cc' unless ($cmd);
   $cmd = &remove_option_pairs($cmd)
			if ($ENV{DBD_INFORMIX_ESQLLD_REMOVE_OPTION_PAIRS});
my @cmd = split /\s+/, $cmd;

print STDERR "+ @cmd @ARGS\n" if debug;
exec @cmd, @ARGS;
