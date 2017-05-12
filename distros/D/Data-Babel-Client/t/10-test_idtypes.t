#!/usr/bin/env perl 
# -*-perl-*-

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Test::More;
use FindBin;

use lib;
use t::Build;


#use lib "$FindBin::Bin/../lib";	# for Babel::Data::Client.pm

use vars qw($class %test_request %idtypes_expected);
$class='Data::Babel::Client';
confess "class not initiated" unless defined $class;
use lib "$FindBin::Bin";
require "common_vars.pl";


sub main {
    require_ok($class) or die "failed require_ok($class); aborting\n";

    my $bc=new Data::Babel::Client;
    test_idtypes($bc);
    done_testing();
}

sub test_idtypes {
    my ($bc)=@_;
    my @idtypes=$bc->idtypes;
    my %idtypes=map {($_->[0],$_->[1])} @idtypes;
    
    my $ok=1;
    while (my ($k,$v)=each %idtypes) {
	if (!ok(exists($idtypes_expected{$k}),"found $k")) {
	    $ok=0;
	    next;
	}
	if (!is($idtypes_expected{$k},$idtypes{$k},"$k matches '$v'")) {
	    $ok=0;
	    next;
	}
    }
    $ok;
}

main();
