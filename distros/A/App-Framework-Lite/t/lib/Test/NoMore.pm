package Test::NoMore;

use 5.004;

use strict;


use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS $TODO);
$VERSION = '0.72';
$VERSION = eval $VERSION;    # make the alpha version come out as a number

use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(ok use_ok require_ok
             is isnt like unlike is_deeply
             cmp_ok
             skip todo todo_skip
             pass fail
             eq_array eq_hash eq_set
             $TODO
             plan
             can_ok  isa_ok
             diag
	     BAIL_OUT
            );


sub plan {
	print "Planning @_\n" ;
}



sub ok ($;$) {
    my($test, $name) = @_;
	print "ok(@_)\n" ;
}

sub is ($$;$) {
}

sub isnt ($$;$) {
}

sub like ($$;$) {
}


sub unlike ($$;$) {
    my $tb = Test::More->builder;

    $tb->unlike(@_);
}



sub cmp_ok($$$;$) {
}



sub can_ok ($@) {
    my($proto, @methods) = @_;
    my $class = ref $proto || $proto;
	my $ok=1 ;
	
    return $ok;
}


sub isa_ok ($$;$) {
    my($object, $class, $obj_name) = @_;
    my $ok=1;

    return $ok;
}


sub pass (;$) {
}

sub fail (;$) {
}


sub use_ok ($;@) {
    my($module, @imports) = @_;
	my $ok=1;
	
    return $ok;
}

sub require_ok ($) {
    my($module) = shift;
    my $pack = caller;

	my $ok=1;
	
    return $ok;
}




sub is_deeply {
	my $ok=1;
    return $ok;
}


sub diag {
	print "@_\n" ;
}

sub skip {
    my($why, $how_many) = @_;

    local $^W = 0;
    last SKIP;
}

sub todo_skip {
    my($why, $how_many) = @_;

    local $^W = 0;
    last TODO;
}


sub BAIL_OUT {
    my $reason = shift;
}

sub eq_array {
}


sub eq_hash {
}


sub eq_set  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;

    # There's faster ways to do this, but this is easiest.
    local $^W = 0;

    # It really doesn't matter how we sort them, as long as both arrays are 
    # sorted with the same algorithm.
    #
    # Ensure that references are not accidentally treated the same as a
    # string containing the reference.
    #
    # Have to inline the sort routine due to a threading/sort bug.
    # See [rt.cpan.org 6782]
    #
    # I don't know how references would be sorted so we just don't sort
    # them.  This means eq_set doesn't really work with refs.
    return eq_array(
           [grep(ref, @$a1), sort( grep(!ref, @$a1) )],
           [grep(ref, @$a2), sort( grep(!ref, @$a2) )],
    );
}


1;
