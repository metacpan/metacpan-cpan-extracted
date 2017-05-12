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
    test_translate($bc);
    done_testing();
}

sub test_translate {
    my ($bc)=@_;
    my $ok=1;
    eval {
	my $table=$bc->translate(%test_request);

	my %id2count;
	foreach my $row (@$table) {
	    my $input_id=$row->[0];
	    $id2count{$input_id}++;
	}

	foreach my $entrez_id (@{$test_request{input_ids}}) {
	    $ok &= ok($id2count{$entrez_id}>0, "found responses for $entrez_id"); # 
	}
    };
    if ($@) {
	warn "$@ is $@";
	$ok=0;
    }
    $ok;
}

main();
