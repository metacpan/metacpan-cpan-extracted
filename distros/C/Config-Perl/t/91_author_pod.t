#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

# Tests for the Perl module Config::Perl
# 
# Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use Config_Perl_Testlib;

use File::Spec::Functions qw/catfile/;
our @PODFILES;
BEGIN {
	@PODFILES = (
		catfile($FindBin::Bin,qw/ .. lib Config Perl.pm /),
		catfile($FindBin::Bin,qw/ .. lib Data Undump PPI.pm /),
	);
}

use Test::More $AUTHOR_TESTS && !$DEVEL_COVER ? (tests=>1*@PODFILES+3)
	: (skip_all=>$DEVEL_COVER?'skipping during Devel::Cover tests':'author POD tests');

use Test::Pod;

for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
}

# Test the Config::Perl POD Synopsis (copy & paste to/from there)
 use Config::Perl;
 my $parser = Config::Perl->new;
 my $data = $parser->parse_or_die( \<<' END_CONFIG_FILE' );
   # This is the example configuration file
   $foo = "bar";
   %text = ( test => ["Hello", "World!"] );
   @vals = qw/ x y a /;
 END_CONFIG_FILE
 print $data->{'$foo'}, "\n";   # prints "bar\n"

is_deeply $data,
 {
    '$foo'  => "bar",
    '%text' => { test => ["Hello", "World!"] },
    '@vals' => ["x", "y", "a"],
 },
'Config::Perl POD Synopsis';

# Test the Data::Undump::PPI POD Synopsis (copy & paste to/from there)
 use Data::Dumper;
 use Data::Undump::PPI;             # "Undump()" is exported by default
 $Data::Dumper::Purity=1;           # should always be turned on for Undump
 
 my @input = ( {foo=>"bar"}, ["Hello","World"], "undumping!" );
 my $str = Dumper(@input);          # dump the data structure to a string
 my @parsed = Undump($str);         # parse the data structure back out
 # @parsed now looks identical to @input (is a deep copy)
 
 use Data::Undump::PPI qw/Dump Undump/;      # additionally import "Dump()"
 Dump(\@input, file=>'/tmp/test.conf');      # Data::Dumper to file
 my @conf = Undump(file=>'/tmp/test.conf');  # Undump directly from file

is_deeply \@parsed, \@input, 'Data::Undump::PPI POD Synopsis 1';
is_deeply \@conf, \@input, 'Data::Undump::PPI POD Synopsis 2'

