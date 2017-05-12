#!perl -T
#
# $Id: 02-base64.t,v 0.1 2008/06/16 17:34:27 dankogai Exp dankogai $
#

use strict;
use warnings;
use Test::More tests => 20;
#use Test::More qw/no_plan/;
use Convert::BaseN;

my $decoded = "\xFB\xFF\xBF";

my %encoded = (
    base64       => '+/+/',
    base64_url   => '-_-_',
    base64_imap  => '+,+,',
    base64_ircu  => '[][]',
);

for my $name (sort keys %encoded){
    my $cb = Convert::BaseN->new($name);
    my $encoded = $encoded{$name};
    is $cb->encode($decoded, ''), $encoded, qq($name: $encoded);
    for my $to (sort keys %encoded){
	my $b64 = Convert::BaseN->new($to);
	is $b64->decode($encoded), $decoded, qq($name -> $to);
    }
}


