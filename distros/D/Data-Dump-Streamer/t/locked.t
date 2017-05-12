use vars qw /$TESTS/;
use Test::More tests=>2+($TESTS=9);

#$Id: locked.t 26 2006-04-16 15:18:52Z demerphq $#

BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump Dump) ); }
use strict;
use warnings;


# imports same()
(my $helper=$0)=~s/\w+\.\w+$/test_helper.pl/;
require $helper;
# use this one for simple, non evalable tests. (GLOB)
#   same ( $got,$expected,$name,$obj )
#
# use this one for eval checks and dumper checks but NOT for GLOB's
# same ( $name,$obj,$expected,@args )

my $dump;
my $o = Data::Dump::Streamer->new();
isa_ok( $o, 'Data::Dump::Streamer' );
SKIP:{
      skip "No locked hashes before 5.8.0",
           $TESTS
      if $]<5.008;
      skip "Can't tell which keys are locked before 5.8.1",
           $TESTS
      if $]==5.008;
{
    my %h = ('a0'..'a9');
    lock_keys(%h);
    test_dump( {name=>"locked_ref_keys",
                verbose=>1}, $o, ( \%h ),
               <<'EXPECT',  );
$HASH1 = lock_ref_keys( {
           a0 => 'a1',
           a2 => 'a3',
           a4 => 'a5',
           a6 => 'a7',
           a8 => 'a9'
         } );
EXPECT
    delete (@h{qw(a2 a6)});
    test_dump( {name=>"locked_ref_keys_plus",
                verbose=>1}, $o, ( \%h ),
               <<'EXPECT',  );
$HASH1 = lock_ref_keys_plus( {
           a0 => 'a1',
           a4 => 'a5',
           a8 => 'a9'
         }, 'a2', 'a6' );
EXPECT
}
{
    my %h = ('a0'..'a9');
    lock_keys(%h);
    test_dump( {name=>"locked_keys",
                verbose=>1}, $o->Names('*h'), ( \%h ),
               <<'EXPECT',  );
%h = (
       a0 => 'a1',
       a2 => 'a3',
       a4 => 'a5',
       a6 => 'a7',
       a8 => 'a9'
     );
lock_keys( %h );
EXPECT
    delete (@h{qw(a2 a6)});
    test_dump( {name=>"locked_keys_plus",
                verbose=>1}, $o, ( \%h ),
               <<'EXPECT',  );
%h = (
       a0 => 'a1',
       a4 => 'a5',
       a8 => 'a9'
     );
lock_keys_plus( %h, 'a2', 'a6');
EXPECT
    $o->Names();
}
{
    my $h = bless {'a0'..'a9'},'locked';
    lock_keys(%$h);
    test_dump( {name=>"blessed locked_ref_keys",
                verbose=>1}, $o, ( \%$h ),
               <<'EXPECT',  );
$locked1 = lock_ref_keys( bless( {
             a0 => 'a1',
             a2 => 'a3',
             a4 => 'a5',
             a6 => 'a7',
             a8 => 'a9'
           }, 'locked' ) );
EXPECT
    delete (@$h{qw(a2 a6)});
    test_dump( {name=>"blessed locked_ref_keys_plus",
                verbose=>1}, $o, ( \%$h ),
               <<'EXPECT',  );
$locked1 = lock_ref_keys_plus( bless( {
             a0 => 'a1',
             a4 => 'a5',
             a8 => 'a9'
           }, 'locked' ), 'a2', 'a6' );
EXPECT
}
{
    my $h = bless {'a0'..'a9'},'locked';
    lock_keys(%$h);
    test_dump( {name=>"blessed locked_keys",
                verbose=>1}, $o->Names('*h'), ( $h,$h ),
               <<'EXPECT',  );
%h = (
       a0 => 'a1',
       a2 => 'a3',
       a4 => 'a5',
       a6 => 'a7',
       a8 => 'a9'
     );
$locked1 = bless( \%h, 'locked' );
lock_keys( %h );
EXPECT
    delete (@$h{qw(a2 a6)});
    test_dump( {name=>"blessed locked_keys_plus",
                verbose=>1}, $o, ( $h,$h ),
               <<'EXPECT',  );
%h = (
       a0 => 'a1',
       a4 => 'a5',
       a8 => 'a9'
     );
$locked1 = bless( \%h, 'locked' );
lock_keys_plus( %h, 'a2', 'a6');
EXPECT
    $o->Names();
}
{
    my $x=0;
    my %hashes=map { $_=>lock_ref_keys_plus({foo=>$_},$x++) } 1..10;
    lock_keys_plus(%hashes,10..19);
    test_dump( {name=>"blessed locked_keys_plus",
                verbose=>1}, $o, ( \%hashes ),
               <<'EXPECT',  );
$HASH1 = lock_ref_keys_plus( {
           1  => lock_ref_keys_plus( { foo => 1 }, 0 ),
           2  => lock_ref_keys_plus( { foo => 2 }, 1 ),
           3  => lock_ref_keys_plus( { foo => 3 }, 2 ),
           4  => lock_ref_keys_plus( { foo => 4 }, 3 ),
           5  => lock_ref_keys_plus( { foo => 5 }, 4 ),
           6  => lock_ref_keys_plus( { foo => 6 }, 5 ),
           7  => lock_ref_keys_plus( { foo => 7 }, 6 ),
           8  => lock_ref_keys_plus( { foo => 8 }, 7 ),
           9  => lock_ref_keys_plus( { foo => 9 }, 8 ),
           10 => lock_ref_keys_plus( { foo => 10 }, 9 )
         }, 11, 12, 13, 14, 15, 16, 17, 18, 19 );
EXPECT

}




}# SKIP
__END__
# with eval testing
{
    same( "", $o, <<'EXPECT', (  ) );
EXPECT
}
# without eval testing
{
    same( $dump = $o->Data()->Out, <<'EXPECT', "", $o );
EXPECT
}
