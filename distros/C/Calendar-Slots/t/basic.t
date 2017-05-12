use strict;
use warnings;
use Test::More; # tests => 45;
use Calendar::Slots;
use DateTime;
sub _dump {  require YAML; warn YAML::Dump( @_ ) }

{
    my $cal = new Calendar::Slots; 
    my $slot = new Calendar::Slots::Slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( $slot ); 
    is( $slot->weekday, 7, '2009-10-11 is a Sunday');
    is( $cal->name( date=>'2009-10-11', time=>'10:30' ), 'normal', 'time found' );
    ok( $cal->name( date=>'2009-10-11', time=>'11:29' ), 'time found closely' );
    ok( !$cal->name( date=>'2009-10-11', time=>'11:30' ), 'time not found' );
}
{
    my $cal = new Calendar::Slots();
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'11:30', end=>'22:30', name=>'urgent' ); 
    is( $cal->name( date=>'2009-10-11', time=>'11:30' ), 'urgent', 'urgent time found' );
    my $slot = $cal->find( date=>'2009-10-11', time=>'11:30' );
    ok( ref $slot, 'urgent slot object exits'); 
    #$cal->weekday_slot( day=>0, start=>'10:30', end=>'11:30', name=>'normal' );
}
{
    my $cal = new Calendar::Slots();
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'11:30', end=>'22:30', name=>'normal' ); 
    my @rows = $cal->all;
    is( scalar(@rows), 1, 'bottom adjacent slots merged' );
    is( $cal->name( date=>'2009-10-11', time=>'22:29' ), 'normal', 'bottom adjacent normal time found' );
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'1:00', end=>'10:30', name=>'normal' ); 
    my @rows = $cal->all;
    is( scalar(@rows), 1, 'top adjacent slots merged' );
    is( $cal->name( date=>'2009-10-11', time=>'9:30' ), 'normal', 'top adjacent normal time found' );
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    my @rows = $cal->all;
    is( scalar(@rows), 1, 'same slots merged' );
    is( $cal->name( date=>'2009-10-11', time=>'10:30' ), 'normal', 'same normal time found' );
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'11:00', end=>'22:30', name=>'normal' ); 
    my @rows = $cal->all;
    is( scalar(@rows), 1, 'bottom crossed slots merged' );
    is( $cal->name( date=>'2009-10-11', time=>'11:30' ), 'normal', 'bottom crossed normal time found' );
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'1:00', end=>'11:00', name=>'normal' ); 
    my @rows = $cal->all;
    is( scalar(@rows), 1, 'top crossed slots merged' );
    is( $cal->name( date=>'2009-10-11', time=>'1:30' ), 'normal', 'top crossed normal time found' );
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'12:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'0:30', end=>'11:30', name=>'normal' ); 
    my @rows = $cal->all;
    is( scalar(@rows), 1, 'many overlapping slots merged' );
    is( $cal->name( date=>'2009-10-11', time=>'0:30' ), 'normal', 'many overlapping normal time found top' );
    is( $cal->name( date=>'2009-10-11', time=>'11:00' ), 'normal', 'many overlapping normal time found bottom' );
}
{
    my $cal = new Calendar::Slots();
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
    $cal->slot( date=>'2009-10-11', start=>'11:00', end=>'22:30', name=>'urgent' ); 

    is( $cal->name( date=>'2009-10-11', time=>'10:59' ), 'normal', 'overlapping normal time found' );
    is( $cal->name( weekday=>7, time=>'11:00' ), 'urgent', 'overlapping urgent time found' );

    $cal->slot( date=>'2009-10-11', start=>'11:00', end=>'22:00', name=>'normal' ); 
    # N: 10:30 - 22:00, U: 22:00 - 22:30

    is( $cal->name( date=>'2009-10-11', time=>'11:00' ), 'normal', 'split normal time found' );
    is( $cal->name( date=>'2009-10-11', time=>'21:59' ), 'normal', 'split late normal time found' );
    is( $cal->name( date=>'2009-10-11', time=>'22:00' ), 'urgent', 'split urgent time found' );
    is( $cal->num_slots, 2, 'many overlapping slots merged' );

    $cal->slot( date=>'2009-10-11', start=>'12:00', end=>'13:00', name=>'urgent' ); 
    # N: 10:30 - 12:00, U: 12-13, N: 13-22, U: 22:00 - 22:30
    #die _dump $cal;

    is( $cal->name( date=>'2009-10-11', time=>'12:00' ), 'urgent', 'split content urgent time found' );
    is( $cal->num_slots, 4, 'many overlapping slots merged' );

    $cal->slot( date=>'2009-10-11', start=>'11:50', end=>'12:30', name=>'normal' ); 

    is( $cal->name( date=>'2009-10-11', time=>'12:00' ), 'normal', 're-split content normal time found' );
    is( $cal->name( date=>'2009-10-11', time=>'12:30' ), 'urgent', 're-split content urgent time found' );
    is( $cal->num_slots, 4, 'many overlapping slots merged' );

    $cal->slot( date=>'2009-10-11', start=>'11:00', end=>'16:30', name=>'normal' ); 

    is( $cal->num_slots, 2, 'many overlapping slots merged' );
}
{
    # midnight crossed slot
    my $cal = new Calendar::Slots();
    $cal->slot( date=>'2009-10-11', start=>'10:30', end=>'00:30', name=>'normal' ); 
    is( $cal->name( date=>'2009-10-12', time=>'00:15' ), 'normal', 'midnight normal time found' );
    is( $cal->num_slots, 2, 'midnight splitted' );
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>'2009-10-11', start=>'10:00', end=>'13:00', name=>'normal' ); 
    $cal->slot( weekday=>7, start=>'10:30', end=>'11:00', name=>'normal' ); 
    is( $cal->num_slots, 2, 'weekday with date slots not merged' );
    is( $cal->name( weekday=>7, time=>'12:00' ), 'normal', 'weekday normal time found' );
}
{
    #delete slots
    ;
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( start_date=>'2009-10-11', end_date=>'2009-10-14', start=>'10:00', end=>'13:00', name=>'normal' ); 
    is( $cal->num_slots, 4, 'same slot over several days' );
    is( $cal->name( date=>'2009-10-13', time=>'12:30' ), 'normal', 'found slot over serveral days' );
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( start_date=>'2009-10-11', end_date=>'2009-10-14', start=>'12:00', end=>'06:00', name=>'normal' ); 
    #is( $cal->num_slots, 4, 'same slot over several days' );
    is( $cal->name( date=>'2009-10-13', time=>'03:30' ), 'normal', 'found split slot over serveral days' );
    is( $cal->name( date=>'2009-10-13', time=>'09:30' ), '', 'not found split slot over serveral days' );
}
{
    #start_datetime => end_datetime
    ;
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( date=>'2012-08-20', start=>'12:00', end=>'06:00', name=>'normal' ); 
    $cal->slot( date=>'2012-08-22', start=>'12:00', end=>'06:00', name=>'normal2' ); 
    is  $cal->name( weekday=>1, time=>'12:00' ), 'normal', 'convert from weekday to date' ;  # 8-20 is a monday (1)
    is  $cal->name( weekday=>2, time=>'12:00' ), '', 'convert from weekday to date' ;  
    is  $cal->name( weekday=>3, time=>'12:00' ), 'normal2', 'convert from weekday to date' ;  
}

{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'12:00', end=>'06:00', name=>'normal - with text : long' ); 
    is  $cal->name( date=>'2012-08-20', time=>'12:00' ), 'normal - with text : long', 'text arg mod bug' ; 
}

{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'12:00', end=>'06:00', name=>'normal', data=>{ yy=>10, xx=>33 } ); 
    is  $cal->find( date=>'2012-08-20', time=>'12:00' )->data->{xx}, 33, 'data param';
    ok  $cal->find( date=>'2012-08-20', time=>'12:00' )->data->{yy} != 12, 'not data param';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'1200', end=>'1200', name=>'normal', data=>{ yy=>10, xx=>33 } ); 
    $cal->slot( weekday=>1, start=>'1200', end=>'1200', name=>'normal', data=>{ yy=>10, xx=>33 } ); 
    is( $cal->num_slots, 1, 'same slot over several days' );
}

{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'1200', end=>'1200', name=>'normal' );  # created, but ignored
    $cal->slot( weekday=>1, start=>'1230', end=>'1200', name=>'normal' );  # ends next day
    $cal->slot( weekday=>1, start=>'1300', end=>'1200', name=>'normal', data=>99 ); # insider, expanded 
    # warn $cal->as_table;
    is( $cal->num_slots, 2, 'same slot over several days' );
    is( [$cal->all]->[0]->data, 99, 'same slot over several days' );
    is( [$cal->all]->[1]->data, 99, 'same slot over several days' );
}

done_testing;
