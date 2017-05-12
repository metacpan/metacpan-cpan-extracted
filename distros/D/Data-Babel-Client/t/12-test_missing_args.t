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

use vars qw($class %test_request %idtypes_expected);
$class='Data::Babel::Client';
confess "class not initiated" unless defined $class;
use lib "$FindBin::Bin";
require "common_vars.pl";


sub main {
    require_ok($class) or die "failed require_ok($class); aborting\n";

    my $bc=new Data::Babel::Client;
    test_missing_args($bc);
    done_testing();
}

sub test_missing_args {
    my ($bc)=@_;
    my $ok=1;
    foreach my $arg_name (qw(input_ids input_type output_types)) {
	eval {
	    my %args=%test_request;
	    delete $args{$arg_name};
	    $bc->translate(%args);
	    $ok=0;
	};
	ok ($@=~/missing args: $arg_name/, "caught missing $arg_name");
    }
    $ok;
}

main();
