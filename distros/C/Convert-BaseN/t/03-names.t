#!perl -T
#
# $Id: 03-names.t,v 0.1 2008/06/16 17:34:27 dankogai Exp dankogai $
#

use strict;
use warnings;
use Test::More tests => 12;
#use Test::More qw/no_plan/;

use Convert::BaseN;

my $text =
  do { local $/; open my $fh, '<', $0; my $str = <$fh>; close $fh; $str };

for my $name (sort keys %Convert::BaseN::named_encoder){
    my $cb = Convert::BaseN->new($name);
    my $encoded = $cb->encode($text);
    is $cb->decode($encoded), $text, $name;
};
