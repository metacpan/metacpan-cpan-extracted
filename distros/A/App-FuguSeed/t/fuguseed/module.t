#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The lead module App::FuguSeed (QR-PACK-4, TEST-PACK-5).
#
# PAUSE grants the distribution name through the package of this
# module, and it indexes the distribution through that package.
# scripts/dist refuses a tree where no module declares the package
# that the dist.module key of .toolingrc names, so the name below is
# the name that a release needs. The test compiles the module as
# well: no other test loads it.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use Module::CoreList ();

use constant MODULE => 'App::FuguSeed';
use constant FILE   => 'App/FuguSeed.pm';

# The interpreter before the load. The assertions of QR-PACK-4 below
# read what the load added to it.
my @directory = @INC;
my %preloaded = %INC;

require_ok(MODULE) or BAIL_OUT('the lead module does not compile');

my $path = $INC{ +FILE };
defined $path or BAIL_OUT( 'the lead module names no path in %INC' );

open my $fh, '<', $path or BAIL_OUT("$path: $!");
my $source = do { local $/ = undef; <$fh> };
close $fh or BAIL_OUT("close $path: $!");

# QR-PACK-4: the package name is the name that PAUSE indexes, and it
# is the dist.module key of .toolingrc.
my $module = MODULE;
like( $source, qr/^package[ \t]+\Q$module\E[ \t]*;$/m,
	'the lead module declares the package that PAUSE indexes' );

# QR-PACK-4: the module holds no code, so scripts/pack packs no part
# of it. t/scripts/pack.t proves that the packed file holds the six
# modules of the program and no other package. Each line outside the
# comments is the package statement, a pragma line, or the true value
# at the end. A subroutine, a top-level statement, and a BEGIN block
# each fail this check.
#
# This test ships in the tarball, and scripts/dist stamps one line
# below each package statement of a staged module:
#
#	our $VERSION = '<dotted-decimal>';
#
# The filter accepts that line in its exact form, so the staged test
# passes. It accepts no other our statement, and no other value.
my @statement = grep { !m{\A\s*(?:\#|\z)} } split /\n/, $source;
my @code      = grep {
	     !/\Apackage[ ]\Q$module\E;\z/
	  && !/\A(?:use|no)[ ][a-z][^;]*;\z/
	  && !/\Aour[ ]\$VERSION[ ]=[ ]'[0-9]+(?:\.[0-9]+)+';\z/
	  && !/\A1;\z/
} @statement;
is( "@code", q{}, 'the lead module holds no code' );

# QR-PACK-4: a pragma line carries code as well, so the filter above
# proves too little on its own. "use constant FOO => 1" writes a
# subroutine into this package. "use parent" gives the package a
# parent class. "use lib" adds a directory to @INC, and "use if"
# loads another module. The four assertions below read each of those
# effects out of the interpreter, so this test needs no list of the
# pragma names. Each one writes the package name in full: a name out
# of the MODULE constant would need the pragma no strict 'refs'.

# _routine($entry):
#	The stash entry $entry holds a subroutine. Perl keeps an
#	inlinable constant as a reference, and every other name as a
#	glob.
sub _routine ($entry)
{
	return 1 if ref $entry;

	return defined *{$entry}{CODE} ? 1 : 0;
}

my $stash   = \%App::FuguSeed::;
my @routine = sort grep { _routine( $stash->{$_} ) } keys %{$stash};
is( "@routine", q{}, 'the lead module defines no subroutine' );

is( "@App::FuguSeed::ISA", q{}, 'the lead module has no parent class' );

is( "@INC", "@directory", 'the lead module adds no directory to @INC' );

my @outside;
for my $path ( grep { !$preloaded{$_} } sort keys %INC ) {
	next if $path eq FILE;
	( my $name = $path ) =~ s/\.pm\z//;
	$name                =~ s{/}{::}g;
	push @outside, $name
	    unless Module::CoreList::is_core( $name, undef, 5.034 );
}
is( "@outside", q{}, 'the lead module loads core modules alone' );

done_testing();
