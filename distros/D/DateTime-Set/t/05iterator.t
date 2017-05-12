#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 12;

use DateTime;
use DateTime::Duration;
use DateTime::Set;
use DateTime::SpanSet;

use constant INFINITY     =>       100 ** 100 ** 100 ;
use constant NEG_INFINITY => -1 * (100 ** 100 ** 100);

my $res;

my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
my $s1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

my $month_callback = sub {
            $_[0]->truncate( to => 'month' )
                 ->add( months => 1 );
        };


# "START"
my $months = DateTime::Set->from_recurrence( 
    recurrence => $month_callback, 
    start => $t1,
);
$res = $months->min;
$res = $res->ymd if ref($res);
is( $res, '1810-09-01', 
    "min() - got $res" );


my $iterator = $months->iterator;
my @res;
for (1..3) {
        my $tmp = $iterator->next;
        push @res, $tmp->ymd if defined $tmp;
}
$res = join( ' ', @res );
is( $res, '1810-09-01 1810-10-01 1810-11-01',
        "3 iterations give $res" );


# sub-second iterator
{
    my $count = 0;
    my $micro_callback = sub {
            # truncate and add to 'microsecond'
            $_[0]->set( nanosecond =>
                           1000 * int( $_[0]->nanosecond / 1000 ) )
                 ->add( nanoseconds => 1000 );
            # warn "nanosec = ".$_[0]->datetime.'.'.sprintf('%06d',$_[0]->microsecond);

            # guard against an infinite loop error
            return INFINITY if $count++ > 50;  

            return $_[0];
    };
    my $microsec = DateTime::Set->from_recurrence(
        recurrence => $micro_callback,
        start => $t1,
    );
    my $iterator = $microsec->iterator;
    my @res;
    for (1..3) {
        my $tmp = $iterator->next;
        if (defined $tmp) {
            my $str = $tmp->datetime.'.'.sprintf('%06d',$tmp->microsecond);
            # warn "iter: $str";
            push @res, $str;
        }
    }

    $res = join( ' ', @res );
    is( $res, '1810-08-22T00:00:00.000000 1810-08-22T00:00:00.000001 1810-08-22T00:00:00.000002',
        "3 iterations give $res" );
}

# test the iterator limits.  Ben Bennett.
{
    # Make a recurrence that returns all months
    my $all_months = DateTime::Set->from_recurrence( recurrence => $month_callback );

    my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
    my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
    my $span = DateTime::Span->from_datetimes( start => $t1, end => $t2 );

    # make an iterator with an explicit span argument
    my $iter = $all_months->iterator( span => $span );
    
    # And make sure that we run on the correct months only
    my $limit = 4; # Make sure we don't hit an infinite iterator
    my @res = ();
    while ( my $dt = $iter->next() and $limit--) {
        push @res, $dt->ymd();
    }
    my $res = join( ' ', @res);
    is( $res, '1810-09-01 1810-10-01 1810-11-01',
        "limited iterator give $res" );

  {
    # Make another iterator over a short time range
    my $iter = $all_months->iterator( start => $t1, end => $t2 );
    
    # And make sure that we run on the correct months only
    $limit = 4; # Make sure we don't hit an infinite iterator
    @res = ();
    while ( my $dt = $iter->next() and $limit--) {
        push @res, $dt->ymd();
    }
    $res = join( ' ', @res);
    is( $res, '1810-09-01 1810-10-01 1810-11-01',
        "limited iterator give $res" );
  }

    # And try looping just using a start date and get 4 items
    # to make sure that we didn't damage the original set
    $iter = $all_months->iterator( start => $t1 );
    $limit = 4;
    @res = ();
    while ( my $dt = $iter->next() and $limit--) {
        push @res, $dt->ymd();
    }
    $res = join( ' ', @res);
    is( $res, '1810-09-01 1810-10-01 1810-11-01 1810-12-01',
        "limited iterator give $res" );
}
 

# test SpanSet iterator
{
    # Make a recurrence that returns all months
    my $all_months = DateTime::Set->from_recurrence( recurrence => $month_callback );
    $all_months = DateTime::SpanSet->from_sets(
        start_set => $all_months, end_set => $all_months ); 

    my $t1 = new DateTime( year => '1810', month => '08', day => '22' );
    my $t2 = new DateTime( year => '1810', month => '11', day => '24' );
    my $span = DateTime::Span->from_datetimes( start => $t1, end => $t2 );

  {
    # make an iterator with an explicit span argument
    my $iter = $all_months->iterator( span => $span );
    
    # And make sure that we run on the correct months only
    my $limit = 4; # Make sure we don't hit an infinite iterator
    my @res = ();
    while ( my $span = $iter->next() and $limit--) {
        push @res, $span->min->ymd() . "," . $span->max->ymd();
    }
    my $res = join( ' ', @res);
    is( $res, '1810-08-22,1810-09-01 1810-09-01,1810-10-01 '.
              '1810-10-01,1810-11-01 1810-11-01,1810-11-24',
        "limited iterator give $res" );
  }

  {
    # make an iterator, again.
    my $iter = $all_months->iterator( span => $span );

    # And make sure that we run on the correct months only
    my $limit = 4; # Make sure we don't hit an infinite iterator
    my @res = ();
    while ( my $span = $iter->previous() and $limit--) {
        push @res, $span->min->ymd() . "," . $span->max->ymd();
    }
    my $res = join( ' ', @res);
    is( $res, '1810-11-01,1810-11-24 1810-10-01,1810-11-01 '.
              '1810-09-01,1810-10-01 1810-08-22,1810-09-01',
        "limited iterator give $res" );
  }
}
 

{
    # test intersections with open/closed ended spans

    # Make a recurrence that returns all months
    my $all_months = DateTime::Set->from_recurrence( recurrence => $month_callback );

    my $t1 = new DateTime( year => '1810', month => '9',  day => '1' );
    my $t2 = new DateTime( year => '1810', month => '11', day => '1' );

    {
        my $span = DateTime::Span->from_datetimes( start => $t1, end => $t2 );

        # make an iterator with an explicit span argument
        my $iter = $all_months->iterator( span => $span );
        
        # And make sure that we run on the correct months only
        my $limit = 4; # Make sure we don't hit an infinite iterator
        my @res = ();
        while ( my $dt = $iter->next() and $limit--) {
            push @res, $dt->ymd();
        }
        my $res = join( ' ', @res);
        is( $res, '1810-09-01 1810-10-01 1810-11-01',
            "limited iterator give $res" );
    }

    {
        my $span = DateTime::Span->from_datetimes( start => $t1, before => $t2 );

        # make an iterator with an explicit span argument
        my $iter = $all_months->iterator( span => $span );
        
        # And make sure that we run on the correct months only
        my $limit = 4; # Make sure we don't hit an infinite iterator
        my @res = ();
        while ( my $dt = $iter->next() and $limit--) {
            push @res, $dt->ymd();
        }
        my $res = join( ' ', @res);
        is( $res, '1810-09-01 1810-10-01',
            "limited iterator give $res" );
    }

    {
        my $span = DateTime::Span->from_datetimes( after => $t1, end => $t2 );

        # make an iterator with an explicit span argument
        my $iter = $all_months->iterator( span => $span );
        
        # And make sure that we run on the correct months only
        my $limit = 4; # Make sure we don't hit an infinite iterator
        my @res = ();
        while ( my $dt = $iter->next() and $limit--) {
            push @res, $dt->ymd();
        }
        my $res = join( ' ', @res);
        is( $res, '1810-10-01 1810-11-01',
            "limited iterator give $res" );
    }

    {
        my $span = DateTime::Span->from_datetimes( after => $t1, before => $t2 );

        # make an iterator with an explicit span argument
        my $iter = $all_months->iterator( span => $span );
        
        # And make sure that we run on the correct months only
        my $limit = 4; # Make sure we don't hit an infinite iterator
        my @res = ();
        while ( my $dt = $iter->next() and $limit--) {
            push @res, $dt->ymd();
        }
        my $res = join( ' ', @res);
        is( $res, '1810-10-01',
            "limited iterator give $res" );
    }
}

1;

