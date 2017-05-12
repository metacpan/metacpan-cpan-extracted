#!/usr/bin/env perl 
# -*-perl-*-

use strict;
use warnings;
use Carp;
use Data::Dumper;
use Test::More;
use FindBin;

use lib;
use t::lib;
use t::Build;

use vars qw($class %test_request %idtypes_expected);
$class='Data::Babel::Client';
confess "class not initiated" unless defined $class;
use lib "$FindBin::Bin";
require "common_vars.pl";


sub main {
    require_ok($class) or die "failed require_ok($class); aborting\n";

    my $bc=new Data::Babel::Client(base_url=>'http://test-babel.gdxbase.org/cgi-bin/translate.cgi');
    test_bad_args_idtypes($bc);
    test_bad_args($bc);
    done_testing();
}

sub test_bad_args_idtypes {
    my ($bc)=@_;
    
    # first get answer from correct call:
    my $idtypes;
    eval { $idtypes=$bc->idtypes(); };
    is ($@,'') or BAIL_OUT("error calling babel service: $@");

    # compare against bad calls; should be the same:
    my $idtypes2;
    eval { $idtypes2=$bc->idtypes(request_type=>'translate') };
    is ($@,'') or BAIL_OUT("error calling babel service: $@");
    is_deeply($idtypes,$idtypes2,"idtypes(): corrected incorrect 'request_type'");
    
    eval { $idtypes2=$bc->idtypes(output_format=>'html') };
    is ($@,'') or BAIL_OUT("error calling babel service: $@");
    is_deeply($idtypes,$idtypes2,"idtypes(): corrected incorrect 'output_format");
    
    eval { $idtypes2=$bc->idtypes(input_type=>'gene_entrez') };	
    is ($@,'') or BAIL_OUT("error calling babel service: $@");
    is_deeply($idtypes,$idtypes2,"idtypes(): ignored extraneous arg 'input_type'");
    
}


sub test_bad_args {
    my ($bc)=@_;

    eval {
	my %args=%test_request;
	$args{input_ids}='29833.1';   # invalid id
	my $t=$bc->translate(%args);
	is(ref $t, 'ARRAY') &&
	    is(@$t,0) ;
	
    };
    ok ($@ eq '', "no thrown exceptions");

    eval {
	my %args=%test_request;
	$args{input_ids}='29833';   # returns array of undefs, except for input
#	warn "$0: args are ",Dumper(\%args);
	my $t=$bc->translate(%args);
#	warn "t is ",Dumper($t);
	is(ref $t, 'ARRAY', "got arrayref...") &&
	    is(@$t,0,"...of length 0");

# did Nat change the behaviour here?  These used to work, as did the above with value=1, not 0
#	    is (ref $t->[0],'ARRAY',"...first element also an array ref...") &&
#	    is ($t->[0]->[0],29833, "...got empty array for known but non-connected id");
#	my $c=grep {!defined $_} @{$t->[0]};
#	is ($c, 5,"got five elements");
	
    };
    ok ($@ eq '', "no thrown exceptions");


    # test bad input_type 'fred'
    eval {
	my %args=%test_request;
	$args{input_type}='fred';
	my $t=$bc->translate(%args);
	is (ref $t, 'HASH') &&
	    is ((keys %$t),1) &&
	    ok (defined $t->{error}) &&
	    ok ($t->{error}=~/unknown type/, "caught bad input_type");
    };
    ok ($@ eq '', "no thrown exceptions");

    # test bad output_type 'gene_symbol2'
    eval {
	my %args=%test_request;
	$args{output_types}='gene_symbol2';
	my $t=$bc->translate(%args);
	is (ref $t, 'HASH') &&
	    is ((keys %$t),1) &&
	    ok (defined $t->{error}) &&
	    ok ($t->{error}=~/unknown type/, "caught unknown output_type");
    };
    ok ($@ eq '', "no thrown exceptions");

    # test input_ids and input_ids_all given together:
    eval {
	my %args=%test_request;
	$args{input_ids_all}=1;
	my $t=$bc->translate(%args);
	warn "t is ",Dumper($t);
    };
    my $expected_error='translate: cannot request both input_ids and input_ids_all';
    my $err_len=length($expected_error); # error actually only starts with above string; also contains file & line number, etc.
    is (substr($@,0,$err_len),$expected_error, "caught presense of both input_ids and input_ids_all");

    # bad output_format should get over-written by client:
    my ($t1,$t2);
    eval { $t1=$bc->translate(%test_request) };
    ok ($@ eq '') or BAIL_OUT("error connecting to service: $@");

    eval {
	my %args=%test_request;
	$args{output_format}='html';
	$t2=$bc->translate(%args);
	is_deeply($t1,$t2,"corrected bad output_format");
    };
    ok ($@ eq '', "no thrown exceptions");

    # bad request_type to translate() should get corrected:
    eval {
	my %args=%test_request;
	$args{request_type}='idtypes';
	$t2=$bc->translate(%args);
	is_deeply($t1,$t2,"corrected bad request_type");
    };
    ok ($@ eq '', "no thrown exceptions");


}

main();
