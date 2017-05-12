#!/usr/bin/perl -w -I../lib -I./lib/
#
#  Test that the Text::Template module works as expected.
#
# Steve
# --
#


use strict;
use Test::More qw! no_plan !;
use File::Temp qw/ tempfile /;

#
#  Load the template module
#
BEGIN {use_ok('Text::Template');}
require_ok('Text::Template');



#
#  Template variables we'll interpolate - came from my desktop.
#
our %template = ( arch         => 'amd64',
                  bits         => '64',
                  distribution => 'Debian',
                  domain       => 'precious',
                  dump         => undef,
                  fqdn         => 'precious',
                  hostname     => 'precious',
                  ip1          => '192.168.0.10',
                  ipcount      => '1',
                  kernel       => '2.6.32-5-amd64',
                  nodelete     => '1',
                  noexecute    => '0',
                  os           => 'linux',
                  prefix       => '/home/skx/hg/trash.d',
                  raid         => 'software',
                  release      => 'squeeze',
                  server       => 'static.steve.org.uk',
                  softwareraid => '1',
                  transport    => 'hg',
                );


#
#  The input we'll expand, and what we expect it to result in.
#
my $input  = "This script is running on {\$fqdn}, with version {\$release}\n";
my $output = "This script is running on precious, with version squeeze\n";

#
#  Create the helper object.
#
my $template = Text::Template->new( TYPE   => 'string',
                                    SOURCE => $input );


#
#  Run the expansion
#
my $expansion = $template->fill_in( HASH => \%template );

#
#  Test the results.
#
ok( $expansion ne $input, "The expansion resulted in a change." );
ok( $expansion eq $output, "The expansion resulted in the text we expected." );

#
#  More specific tests.
#
ok( $expansion =~ /precious/,
    "The expansion resulted in the hostname being inserted." );
ok( $expansion =~ /squeeze/,
    "The expansion resulted in the distribution being inserted." );
