# --8<--8<--8<--8<--
#
# Copyright (C) 2006 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::Funtools::Parse.cvs
#
# Astro::Funtools::Parse.cvs is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# Astro::Funtools::Parse.cvs is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the 
#       Free Software Foundation, Inc. 
#       51 Franklin Street, Fifth Floor
#       Boston, MA  02110-1301, USA
#
# -->8-->8-->8-->8--

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::More;
use Data::Dumper;

use strict;
use warnings;

my @funcnts;
my @funhist;

BEGIN {
    # use readdir instead of globs b/c of 5.6.0 multithreaded perl debug bug
    opendir( DIR, "data" ) or die( "couldn't open data directory\n" );
    my @files = grep { -f "data/$_" } readdir( DIR );
    closedir( DIR );

    @funcnts = grep { /^funcnts.*\.log$/ } @files;
    @funhist = grep { /^funhist.*\.log$/ } @files;

    plan( tests => @funcnts + @funhist + 1 );
}


BEGIN { use_ok( 'Astro::Funtools::Parse' ) };

use Astro::Funtools::Parse qw( parse_funcnts_file parse_funhist_file );

# set to true to generate expected results.
our $create = 0; 



for my $file ( @funcnts )
{
  my ($p) = parse_funcnts_file( "data/$file" );

  ok( cmp_file( $p, "data/$file.p" ), "funcnts $file" );
}

for my $file ( @funhist )
{
  my ( $hdr, $table ) = parse_funhist_file( "data/$file" );
  ok( cmp_file( { hdr=> $hdr, table => $table }, "data/$file.p" ), "funhist $file" );
}

sub cmp_file
{
  my ( $p, $file ) = @_;

  my $c;

  if ( $create )
  {
    open FILE, ">$file" or die( "unable to create $file\n" );
    print FILE Data::Dumper->Dump( [$p], ['c'] );
    close FILE
  }

  {
    open FILE, $file or die( "unable to open $file\n" );
    local $/ = undef;
    my $w = <FILE>;
    close FILE;
    eval $w;
  }

  eq_hash( $c, $p );
}
