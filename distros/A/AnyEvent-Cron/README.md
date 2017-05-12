# AnyEvent-Cron

    my $cron = AnyEvent::Cron->new( 
            verbose => 1,
            debug => 1,
            after => 1,
            interval => 1,
            ignore_floating => 1
    );

    # 00:00 (hour:minute)
    $cron->add("00:00" => sub { warn "zero"; })

        # hour : minute : second 
        ->add( "*:*:10" => sub { })
        ->add( "1:*:*" => sub { })

        ->add( DateTime->now => sub { warn "datetime now" } )
        ->run();

or:

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
    });

    $cron->add({
        type => 'datetime' ,
        callback => sub { warn "DATETIME TRIGGED"  },
        datetime => (sub { 
                return DateTime->now->add_duration( DateTime::Duration->new( minutes => 0 ) ); })->()
        });

    my $cv = AnyEvent->condvar;
    $cv->recv;


## INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

