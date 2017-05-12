use strict;
use warnings;
use Test::More; 
use Calendar::Slots;
use DateTime;
sub _dump {  require YAML; warn YAML::Dump( @_ ) }

{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'10:00', end=>'14:00', name=>'normal' );
    $cal->slot( weekday=>1, start=>'12:00', end=>'14:00', name=>'normal' );
    my $slot = $cal->find( weekday=>1, time=>'11:00' );
    ok ref $slot, 'ok overlap ref';
    is  $cal->find( weekday=>1, time=>'11:00' )->name, 'normal' , 'ok overlap'
        if ref $slot;
    is scalar( $cal->all ), 1, 'overlap just one';
    # _dump [ $cal->all ];
}
{
    # make sure dates are converted to weekdays and merged
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'14:00', name=>'normal' );
    is scalar( $cal->all ), 2, 'date + wk, overlap just one';
    #ok $cal->find( weekday=>1, time=>'13:00' )->end eq 15, 'merged date + wk';
    #my ($first) = $cal->all;
    #ok $first->start eq '0000', 'date + wk start';
    #ok $first->end eq '1400', 'date + wk start';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'14:00', name=>'normal' );
    $cal->slot( date=>20110822, start=>'12:00', end=>'23:30', name=>'normal' );

    my $mat = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $mat->num_slots , 1, 'just one slot';
    my $slot = $mat->find( weekday=>1, time=>'11:00' );
    is $slot->end , '1500', 'just one slot';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'normal' );
    $cal->slot( date=>20110822, start=>'12:00', end=>'23:30', name=>'normal' );

    my $mat = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $mat->num_slots , 1, 'just one slot2';
    my $slot = $mat->find( weekday=>1, time=>'19:00' );
    is $slot->end , '2100', 'just one slot2';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( weekday=>2, start=>'00:00', end=>'10:00', name=>'normal' ); # tue
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'normal' ); 
    $cal->slot( date=>20110823, start=>'12:00', end=>'23:30', name=>'normal' ); # tue

    $cal = $cal->week_of( '2011-08-24' );  # wed; monday on 8/22
    is $cal->num_slots , 3, 'three materialized';
    my $slot = $cal->find( weekday=>2, time=>'19:00' );
    is $slot->end , '2330', 'just one slot2';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'24:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'normal' ); 
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $cal->num_slots , 1, 'one materialized';
    #my $slot = $cal->find( weekday=>2, time=>'19:00' );
    #is $slot->end , '2330', 'just one slot2';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'24:00', name=>'B' );
    $cal->slot( weekday=>1, start=>'04:30', end=>'13:00', name=>'U' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'N' ); 
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    #_dump $cal;
    #_dump [ $cal->sorted ];
    is $cal->num_slots , 4, 'four date materialized';
    my $slot = $cal->find( weekday=>1, time=>'19:00' );
    is $slot->end , '2100', 'split slot';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'N' ); 
    $cal->slot( weekday=>1, start=>'00:00', end=>'24:00', name=>'B' );
    $cal->slot( weekday=>1, start=>'04:30', end=>'13:00', name=>'U' );
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    #_dump $cal;
    #_dump [ $cal->sorted ];
    is $cal->num_slots , 4, 'unsorted date four date materialized';
    my $slot = $cal->find( weekday=>1, time=>'19:00' );
    is $slot->end , '2100', 'split slot N';
    is $slot->name , 'N', 'split slot N';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>6, start=>'00:00', end=>'24:00', name=>'B' );
    $cal->slot( date=>20120901, start=>'1730', end=>'2030', name=>'N' ); 
    $cal->slot( date=>20120901, start=>'1330', end=>'1800', name=>'N' ); 
    $cal->slot( weekday=>6, start=>'0600', end=>'0700', name=>'N' );
    $cal->slot( weekday=>6, start=>'0130', end=>'0330', name=>'N' );
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $cal->num_slots , 7, 'merging unsorted date four date materialized';
    my $slot = $cal->find( weekday=>6, time=>'19:00' );
    is $slot->start , '1330', 'split slot N';
    is $slot->end , '2030', 'split slot N';
    is $slot->name , 'N', 'split slot N';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>6, start=>'00:00', end=>'24:00', name=>'B' );
    $cal->slot( date=>20120901, start=>'1330', end=>'1800', name=>'X' ); 
    $cal->slot( date=>20120901, start=>'2200', end=>'2400', name=>'N' );  # TEST: last has precedence
        # warn $cal->as_table;
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
        # warn $cal->as_table;
    is $cal->num_slots , 4, 'last - first unsorted date four date materialized';
    my $slot = $cal->find( weekday=>6, time=>'2100' );
    is $slot->start , '1800', 'split slot B';
    is $slot->end , '2200', 'split slot B';
    is $slot->name , 'B', 'split slot B';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>6, start=>'00:00', end=>'24:00', name=>'B' );
    $cal->slot( date=>20120901, start=>'1330', end=>'1800', name=>'X' ); 
    $cal->slot( date=>20120901, start=>'1730', end=>'2030', name=>'N' );  # TEST: last has precedence
        # warn $cal->as_table;
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
        # warn $cal->as_table;
    is $cal->num_slots , 4, 'last - first unsorted date four date materialized';
    my $slot = $cal->find( weekday=>6, time=>'19:00' );
    is $slot->start , '1730', 'split slot N';
    is $slot->end , '2030', 'split slot N';
    is $slot->name , 'N', 'split slot N';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>6, start=>'00:00', end=>'24:00', name=>'B' );
    $cal->slot( date=>20120901, start=>'1730', end=>'2030', name=>'N' ); 
    $cal->slot( date=>20120901, start=>'1330', end=>'1500', name=>'N' ); 
    $cal->slot( weekday=>6, start=>'0600', end=>'0700', name=>'N' );
    $cal->slot( weekday=>6, start=>'0130', end=>'0330', name=>'N' );
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $cal->num_slots , 9, 'unsorted date four date materialized';
    my $slot = $cal->find( weekday=>6, time=>'16:00' );
    is $slot->end , '1730', 'split slot N';
    is $slot->name , 'B', 'split slot N';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>20120827, start=>'0000', end=>'2400', name=>'N' ); 
    $cal->slot( weekday=>1, start=>'15:00', end=>'22:30', name=>'N' );
    $cal->slot( weekday=>1, start=>'0700', end=>'1500', name=>'U' );
    # warn $cal->as_table();
    $cal = $cal->week_of( '2012-08-27' );  # wed; monday on 8/27
    # warn $cal->as_table();
    is $cal->num_slots , 1, 'materialized overall';
    my $slot = $cal->find( weekday=>1, time=>'16:00' );
    is $slot->type , 'date', 'found overall';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>20120827, start=>'0000', end=>'2400', name=>'N' ); 
    $cal->slot( weekday=>1, start=>'0000', end=>'0700', name=>'B' );
    #$cal->slot( weekday=>1, start=>'0700', end=>'1500', name=>'U' );
    #$cal->slot( weekday=>1, start=>'1500', end=>'2400', name=>'B' );
     # warn $cal->as_table();
    $cal = $cal->week_of( '2012-08-27' );  # wed; monday on 8/27
     # warn $cal->as_table();
    is $cal->num_slots , 1, 'materialized overall';
    my $slot = $cal->find( weekday=>1, time=>'16:00' );
    is $slot->type , 'date', 'found overall';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>20120827, start=>'0000', end=>'2400', name=>'U' ); 
    $cal->slot( weekday=>1, start=>'15:00', end=>'22:30', name=>'N' );
    $cal = $cal->week_of( '2012-08-27' );  # wed; monday on 8/27
    is $cal->num_slots , 1, 'materialized overall';
    my $slot = $cal->find( weekday=>1, time=>'16:00' );
    is $slot->type , 'date', 'found overall';
    is $slot->name , 'U', 'found overall';
}

done_testing;
