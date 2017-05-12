#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 53;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
use DateTime::SpanSet;
# use warnings;

use constant INFINITY     => DateTime::INFINITY;
use constant NEG_INFINITY => DateTime::NEG_INFINITY;

sub str { 
    if ( ref($_[0]) ) {
        return $_[0]->datetime if $_[0]->is_finite;
        return INFINITY if $_[0]->isa( "DateTime::Infinite::Future" );
        return NEG_INFINITY;
    }
    return $_[0];
}

sub span_str { eval { str($_[0]->min) . '..' . str($_[0]->max) } }

#======================================================================
# SPANSET TESTS
#====================================================================== 

{
    my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
    my $end1   = new DateTime( year => '1811', month => '10', day => '21' );
    my $start2 = new DateTime( year => '1812', month => '11', day => '22' );
    my $end2   = new DateTime( year => '1813', month => '12', day => '23' );

    my $start_set = DateTime::Set->from_datetimes( dates => [ $start1, $start2 ] );
    my $end_set   = DateTime::Set->from_datetimes( dates => [ $end1, $end2 ] );

    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $end_set );

    my $iter = $s1->iterator;

    my $res = span_str( $iter->next );
    is( $res, '1810-09-20T00:00:00..1811-10-21T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1812-11-22T00:00:00..1813-12-23T00:00:00',
        "got $res" );

    # reverse with start/end dates
    $s1 = DateTime::SpanSet->from_sets( start_set => $end_set, end_set => $start_set );

    $iter = $s1->iterator;

    $res = span_str( $iter->next );
    is( $res, NEG_INFINITY.'..1810-09-20T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1811-10-21T00:00:00..1812-11-22T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1813-12-23T00:00:00..'.INFINITY,
        "got $res" );

    # as_list
    my @spans = $s1->as_list;
    isa_ok ( $spans[0], 'DateTime::Span' );
    $res = span_str( $spans[0] );
    is( $res, NEG_INFINITY.'..1810-09-20T00:00:00',
        "as_list got $res" );

    # intersected_spans
    my $intersected = $s1->intersected_spans( $end1 );
    $res = span_str( $intersected );
    # diag "intersected with ". span_str( $s1 );
    is( $res, $end1->datetime .'..'.$start2->datetime,
        "intersected got $res" );
    

  {
    # next( $dt )
    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $end_set );

    my $dt = new DateTime( year => '1809', month => '8',  day => '19' );
    my $next = $s1->next( $dt );
    $res = span_str( $next );
    is( $res, '1810-09-20T00:00:00..1811-10-21T00:00:00',
        "next dt got $res" );
    is( $next->end_is_open, 1, 'end is open' );
    is( $next->start_is_open, 0, 'start is closed' );
    # next( $span )
    $next = $s1->next( $next );
    $res = span_str( $next );
    is( $res, '1812-11-22T00:00:00..1813-12-23T00:00:00',
        "next span got $res" );
    is( $next->end_is_open, 1, 'end is open' );
    is( $next->start_is_open, 0, 'start is closed' );
  }

  {
    # previous( $dt )
    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $end_set );

    my $dt = new DateTime( year => '1812', month => '11',  day => '25' );
    my $previous = $s1->previous( $dt );
    $res = span_str( $previous );
    is( $res, '1810-09-20T00:00:00..1811-10-21T00:00:00',
        "previous dt got $res" );

    my $current = $s1->current( $dt );
    $res = span_str( $current );
    is( $res, '1812-11-22T00:00:00..1813-12-23T00:00:00',
        "current dt got $res" );

    my $closest = $s1->closest( $dt );
    $res = span_str( $closest );
    is( $res, '1812-11-22T00:00:00..1813-12-23T00:00:00',
        "closest dt got $res" );

    $dt = new DateTime( year => '1812', month => '11', day => '20' );
    $closest = $s1->closest( $dt );
    $res = span_str( $closest );
    is( $res, '1812-11-22T00:00:00..1813-12-23T00:00:00',
        "closest dt got $res" );

    $dt = new DateTime( year => '1811', month => '10', day => '25' );
    $closest = $s1->closest( $dt );
    $res = span_str( $closest );
    is( $res, '1810-09-20T00:00:00..1811-10-21T00:00:00',
        "closest dt got $res" );

    $dt = new DateTime( year => '1812', month => '8',  day => '19' );
    $previous = $s1->previous( $dt );
    $res = span_str( $previous );
    is( $res, '1810-09-20T00:00:00..1811-10-21T00:00:00',
        "previous dt got $res" );
    is( $previous->end_is_open, 1, 'end is open' );
    is( $previous->start_is_open, 0, 'start is closed' );
    # previous( $span )
    $previous = $s1->previous( $previous );
    is( $previous, undef , 'no previous' );

    #$res = span_str( $previous );
    #is( $res, NEG_INFINITY.'..1810-09-20T00:00:00',
    #    "previous span got $res" );
    #is( eval{ $previous->end_is_open }, 1, 'end is open' );
    #is( eval{ $previous->start_is_open }, 1, 'start is open' );
    #is( eval{ $previous->duration->delta_seconds }, INFINITY, 'span size is infinite' );
  }

    # TODO: {
    # local $TODO = 'spanset duration should be an object';
    # eval { 

      is ( $s1->duration->delta_seconds, INFINITY, 
        'spanset size is infinite' );

    # } or
    #    ok( 0, 'not a duration object' );
    # }

}

# special case: end == start
{
    my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
    my $end1   = new DateTime( year => '1811', month => '10', day => '21' );
    my $start2 = new DateTime( year => '1811', month => '10', day => '21' );
    my $end2   = new DateTime( year => '1812', month => '11', day => '22' );

    my $start_set = DateTime::Set->from_datetimes( dates => [ $start1, $start2 ] );
    my $end_set   = DateTime::Set->from_datetimes( dates => [ $end1, $end2 ] );

    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $end_set );

    my $iter = $s1->iterator;

    my $res = span_str( $iter->next );
    is( $res, '1810-09-20T00:00:00..1811-10-21T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1811-10-21T00:00:00..1812-11-22T00:00:00',
        "got $res" );
}

# special case: start_set == end_set
{
    my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
    my $start2 = new DateTime( year => '1811', month => '10', day => '21' );
    my $start3 = new DateTime( year => '1812', month => '11', day => '22' );
    my $start4 = new DateTime( year => '1813', month => '12', day => '23' );

    my $start_set = DateTime::Set->from_datetimes( 
       dates => [ $start1, $start2, $start3, $start4 ] );

    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $start_set );

    my $iter = $s1->iterator;

    my $res = span_str( $iter->next );
    is( $res, NEG_INFINITY.'..1810-09-20T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1810-09-20T00:00:00..1811-10-21T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1811-10-21T00:00:00..1812-11-22T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1812-11-22T00:00:00..1813-12-23T00:00:00',
        "got $res" );

    $res = span_str( $iter->next );
    is( $res, '1813-12-23T00:00:00..'.INFINITY,
        "got $res" );
}

# special case: start_set == end_set == recurrence
{
    my $start_set = DateTime::Set->from_recurrence(
       next  => sub { $_[0]->truncate( to => 'day' )
                           ->add( days => 1 ) },
       span => DateTime::Span->from_datetimes(
                   start => new DateTime( year =>  '1810', 
                                          month => '9',  
                                          day =>   '20' )
               ),
    );

# test if the recurrence works properly
    my $set_iter = $start_set->iterator;

    my $res = str( $set_iter->next );
    is( $res, '1810-09-20T00:00:00',
        "recurrence works properly - got $res" );
    $res = str( $set_iter->next );
    is( $res, '1810-09-21T00:00:00',
        "recurrence works properly - got $res" );

# create spanset
    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $start_set );
    my $iter = $s1->iterator;

    $res = span_str( $iter->next );
    is( $res, NEG_INFINITY.'..1810-09-20T00:00:00',
        "start_set == end_set recurrence works properly - got $res" );

    $res = span_str( $iter->next );
    is( $res, '1810-09-20T00:00:00..1810-09-21T00:00:00',
        "start_set == end_set recurrence works properly - got $res" );

    $res = span_str( $iter->next );
    is( $res, '1810-09-21T00:00:00..1810-09-22T00:00:00',
        "start_set == end_set recurrence works properly - got $res" );
}

# set_and_duration
{
    my $start_set = DateTime::Set->from_recurrence(
       next  => sub { $_[0]->truncate( to => 'day' )
                           ->add( days => 1 ) },
       span => DateTime::Span->from_datetimes(
                   start => new DateTime( year =>  '1810',
                                          month => '9',
                                          day =>   '20' )
               ),
    );
    my $span_set = DateTime::SpanSet->from_set_and_duration(
                       set => $start_set, hours => 1 );

    my $iter = $span_set->iterator;

    my $res = span_str( $iter->next );
    is( $res, '1810-09-20T00:00:00..1810-09-20T01:00:00',
        "start_set == end_set recurrence works properly - got $res" );

    $res = span_str( $iter->next );
    is( $res, '1810-09-21T00:00:00..1810-09-21T01:00:00',
        "start_set == end_set recurrence works properly - got $res" );
}

# test the iterator limits.  Ben Bennett.
{
    my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
    my $end1   = new DateTime( year => '1811', month => '10', day => '21' );
    my $start2 = new DateTime( year => '1812', month => '11', day => '22' );
    my $end2   = new DateTime( year => '1813', month => '12', day => '23' );
    my $end3   = new DateTime( year => '1813', month => '12', day => '1' );
	
    my $start_set = DateTime::Set->from_datetimes( dates => [ $start1, $start2 ] );
    my $end_set   = DateTime::Set->from_datetimes( dates => [ $end1, $end2 ] );
    
    my $s1 = DateTime::SpanSet->from_sets( start_set => $start_set, end_set => $end_set );
 
    my $iter_all    = $s1->iterator;
    my $iter_limit  = $s1->iterator(start => $start1, end => $end3);
    my $iter_limit2 =
        $s1->iterator( span =>
                       DateTime::Span->from_datetimes( start => $start1, end => $end3) );

    my $res_a = span_str( $iter_all->next );
    my $res_l = span_str( $iter_limit->next );
    my $res_2 = span_str( $iter_limit2->next );
    is( $res_a, $res_l,
        "limited iterator got $res_a" );
    is( $res_a, $res_2,
        "other limited iterator got $res_a" );
    
    $res_a = span_str( $iter_all->next );
    $res_l = span_str( $iter_limit->next );
    is( $res_l, '1812-11-22T00:00:00..1813-12-01T00:00:00',
        "limited iterator works properly" );
    is( $res_a, '1812-11-22T00:00:00..1813-12-23T00:00:00',
        "limited iterator doesn't break regular iterator" );
}

{
# start_set / end_set

    my $start1 = new DateTime( year => '1810', month => '9',  day => '20' );
    my $end1   = new DateTime( year => '1811', month => '10', day => '21' );
    my $start2 = new DateTime( year => '1812', month => '11', day => '22' );
    my $end2   = new DateTime( year => '1813', month => '12', day => '23' );
    my $end3   = new DateTime( year => '1813', month => '12', day => '1' );
	
    my $start_set = DateTime::Set->from_datetimes( 
            dates => [ $start1, $start2 ] );
    my $end_set   = DateTime::Set->from_datetimes( 
            dates => [ $end1, $end2 ] );
    
    my $s1 = DateTime::SpanSet->from_sets( 
            start_set => $start_set, 
            end_set => $end_set );
 
    isa_ok( $s1->start_set , "DateTime::Set" , "start_set" );
    isa_ok( $s1->end_set , "DateTime::Set" , "end_set" );

    is( "".$s1->start_set->{set}, "".$start_set->{set} , "start_set" );
    is( "".$s1->end_set->{set}, "".$end_set->{set} , "end_set" );
}

{
# start_set / end_set using recurrences

    my $start_set = DateTime::Set->from_recurrence(
       next  => sub { $_[0]->truncate( to => 'day' )
                           ->add( days => 1 ) },
    );

    my $span_set = DateTime::SpanSet->from_set_and_duration(
                       set => $start_set, hours => 1 );

    my $dt = new DateTime( 
            year => '1810', month => '9',  day => '20', hour => 12 );
    my $res;
    
    $res = span_str( $span_set->next( $dt ) );
    is( $res, '1810-09-21T00:00:00..1810-09-21T01:00:00',
        "next span_set occurrence - got $res" );

    my $set1 = $span_set->start_set;
    $res = $set1->next( $dt );
    is( $res->datetime, '1810-09-21T00:00:00',
        "next span_set-start occurrence - got $res" );

    my $set2 = $span_set->end_set;
    $res = $set2->next( $dt );
    is( $res->datetime, '1810-09-21T01:00:00',
        "next span_set-end occurrence - got $res" );

    ok( ! $span_set->contains( $dt ), 
            "span_set recurrence does not contain" );

    ok( $span_set->contains( 
            DateTime->new(
                year => '1810', month => '9',  day => '20', hour => 0 ) ),
            "span_set recurrence contains, dt == start" );

    ok( ! $span_set->contains( 
            DateTime->new(
                year => '1810', month => '9',  day => '20', hour => 1 ) ),
            "span_set recurrence does not contain, dt == end" );
    
    ok( ! $span_set->intersects( 
            DateTime->new(
                year => '1810', month => '9',  day => '20', hour => 1 ) ),
            "span_set recurrence does not intersect, dt == end" );
}


