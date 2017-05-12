#!/usr/bin/env perl
use AnyEvent::Cron;
my $cron = AnyEvent::Cron->new( verbose => 1 );

# 00:00 (hour:minute)
$cron->add("00:00" => sub { warn "zero"; });

$cron->add( DateTime->now => sub { warn "datetime now" } );

$cron->add({  
    type => 'interval',
    second => 0 ,
    triggered => 0,
    callback => sub { 
        warn "SECOND INTERVAL TRIGGERD";
    },
},{  
    type => 'interval',
    hour => DateTime->now->hour , 
    minute =>  DateTime->now->minute ,
    callback => sub { 
        warn "HOUR+MINUTE INTERVAL TRIGGERD";
    },
},{  
    type => 'interval',
    hour => DateTime->now->hour ,
    callback => sub { 
        warn "HOUR INTERVAL TRIGGERD";
    },
},{  
    type => 'interval',
    minute => DateTime->now->minute ,
    callback => sub { 
        warn "MINUTE INTERVAL TRIGGERD";
    },
},{
    type => 'datetime' ,
    callback => sub { warn "DATETIME TRIGGED"  },
    datetime => (sub { 
            # my $dt = DateTime->now->add_duration( DateTime::Duration->new( minutes => 0 ) );
            my $dt = DateTime->now;
            # $dt->set_second(0);
            # $dt->set_nanosecond(0);
            warn "Next trigger: ", $dt;
            return $dt; })->()
})->run();

my $cv = AnyEvent->condvar;
$cv->recv;
